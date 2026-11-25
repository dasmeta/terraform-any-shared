"""Finding lifecycle, immutable daily lists and persistent per-channel delivery."""
import hashlib
import json
import re
import time
from collections import defaultdict
from datetime import date, datetime, timedelta, timezone
from zoneinfo import ZoneInfo

from .source import SourceError, origin_url

CHANNELS = ('slack', 'teams', 'opsgenie')


def key(value):
    return hashlib.sha256(value.encode('utf-8')).hexdigest()


def clean(value):
    """Scanner content is untrusted; flatten names without altering stored source."""
    return re.sub(r'[\x00-\x1f\x7f]', ' ', str(value))


def opsgenie_summary(summary):
    """One compact description; preserve full oldest titles while the sample fits."""
    header = (f'🚨 Critical Findings Summary\nProject: {summary["project"]}\n'
              f'Branch: {summary["branch"]}\nEngagement ID: {summary["engagement_id"]}\n'
              f'Report Date: {summary["report_date"]}\n\n'
              f'🔴 Open Critical: {summary["open_count"]}\n'
              f'🆕 New (24h): {summary["new_count"]}\n'
              f'✅ Fixed (24h): {summary["fixed_count"]}\n\n'
              '🔎 Critical Findings — Sample\n')

    def render(entries):
        return (header + '\n\n'.join(entries) +
                f'\n\nShowing {len(entries)} of {summary["open_count"]} open critical findings\n'
                f'Source: DefectDojo\nView All Findings: {summary["url"]}')

    def fits(text):
        # Leave room for message/alias/tags in the provider's complete JSON body.
        return len(text) <= 15000 and len(json.dumps(text, ensure_ascii=False).encode('utf-8')) <= 60000

    entries = []
    text = render(entries)
    if not fits(text):
        raise SourceError('summary_header_budget')
    for finding in summary['findings']:
        entry = f'{len(entries) + 1}. {finding["title"]} — {finding["age_days"]} days\n{finding["url"]}'
        candidate = render(entries + [entry])
        if not fits(candidate):
            break
        entries.append(entry)
        text = candidate
    return text


class Engine:
    def __init__(self, source, store, sender, policy, now=None, channels=CHANNELS):
        if (not isinstance(channels, tuple) or not channels
                or any(channel not in CHANNELS for channel in channels)
                or len(set(channels)) != len(channels)):
            raise ValueError('invalid_channels')
        self.channels = channels
        self.source, self.store, self.sender, self.policy = source, store, sender, policy
        self.now = now or datetime.now(timezone.utc)

    def events(self, transition, kind, stream, payload, channels=None):
        return [dict(event_key=key(f'{transition}:{channel}'), channel=channel,
                     stream=stream, kind=kind, payload=dict(payload, transition_id=transition),
                     created_at=self.now) for channel in (self.channels if channels is None else channels)]

    def reconcile(self, previous, observed):
        # Fresh structured identity joins replacement IDs. Existing active alias
        # ownership also stays together if scanner metadata changes in place:
        # splitting that ownership could close an alert with a still-open member.
        ids = list(dict.fromkeys(list(observed) + list(previous)))
        parents = {finding_id: finding_id for finding_id in ids}

        def root(finding_id):
            while parents[finding_id] != finding_id:
                parents[finding_id] = parents[parents[finding_id]]
                finding_id = parents[finding_id]
            return finding_id

        def join(first, second):
            parents[root(second)] = root(first)

        identities = {}
        for finding_id in ids:
            row = observed.get(finding_id, previous.get(finding_id))
            identity = row.get('logical_key')
            if identity:
                if identity in identities:
                    join(identities[identity], finding_id)
                identities[identity] = finding_id
        active_aliases = {entry['alias'] for row in previous.values() if row['open']
                          for entry in self._aliases([row])}
        owners = {}
        for finding_id, row in previous.items():
            for entry in self._aliases([row]):
                alias = entry['alias']
                if alias in active_aliases:
                    if alias in owners:
                        join(owners[alias], finding_id)
                    owners[alias] = finding_id
        groups = defaultdict(lambda: ({}, {}))
        for finding_id in ids:
            prior, current = groups[root(finding_id)]
            if finding_id in previous:
                prior[finding_id] = previous[finding_id]
            if finding_id in observed:
                current[finding_id] = observed[finding_id]
        records, events = {}, []
        for prior, current in groups.values():
            if not current:
                continue
            grouped = any(row.get('logical_key') or row.get('alert_aliases')
                          for row in list(prior.values()) + list(current.values()))
            if grouped:
                rows, transitions = self._reconcile_group(prior, current)
            else:
                rows, transitions = self._reconcile_individual(prior, current)
            records.update(rows)
            events.extend(transitions)
        return records, events

    def _aliases(self, records):
        aliases = {}
        for record in sorted(records, key=lambda row: (row['date'], row['id'])):
            entries = record.get('alert_aliases') or [dict(
                alias=record.get('alert_alias') or f'dd:{self.policy["namespace"]}:{record["id"]}:{record["episode"]}',
                channels=record.get('alert_channels', list(CHANNELS)), episode=record['episode'])]
            for entry in entries:
                alias = entry['alias']
                if alias not in aliases:
                    aliases[alias] = dict(alias=alias, channels=[], episode=entry['episode'])
                aliases[alias]['channels'] = [channel for channel in CHANNELS if channel in
                    set(aliases[alias]['channels']) | set(entry['channels'])]
        return list(aliases.values())

    def _reconcile_group(self, previous, observed):
        prior_open = [row for row in previous.values() if row['open']]
        # An unobserved open member remains unknown, so it keeps the logical
        # alert open even if every member we did read was mitigated.
        effective = dict(previous, **observed)
        open_rows = sorted((row for row in effective.values() if row['open']),
                           key=lambda row: (row['date'], row['id']))
        if not previous and not open_rows:
            return {}, []
        episode = max((row['episode'] for row in previous.values()), default=1)
        events = []
        if open_rows and not prior_open:
            representative = open_rows[0]
            finding_id = str(representative['id'])
            # Reuse the established event builder and episode identities for a
            # single logical transition, including later returns under new IDs.
            prior = {finding_id: dict(next(iter(previous.values())), open=False, episode=episode)} if previous else {}
            rows, events = self._reconcile_individual(prior, {finding_id: representative})
            created = rows[finding_id]
            episode = created['episode']
            aliases = [dict(alias=created['alert_alias'], channels=created['alert_channels'], episode=episode)]
            membership = {finding_id: row['open'] for finding_id, row in effective.items()}
        else:
            aliases = self._aliases(prior_open or list(previous.values()))
            membership = {finding_id: row['open'] or previous.get(finding_id, {}).get(
                'alert_member', previous.get(finding_id, {}).get('open', False))
                for finding_id, row in effective.items()}
            if prior_open and not open_rows:
                # Every previous open ID is freshly known closed here. A
                # non-mitigation reason wins over fixed for mixed closures.
                # Closed members from this same episode retain suppression
                # reasons; membership resets when the logical alert reopens.
                closed = [row for finding_id, row in effective.items() if membership[finding_id]]
                representative = min(closed, key=lambda row: (row['reason'] == 'fixed', row['date'], row['id']))
                finding_id = str(representative['id'])
                for entry in aliases:
                    prior = {finding_id: dict(representative, open=True, episode=entry['episode'],
                                              alert_alias=entry['alias'], alert_channels=entry['channels'])}
                    _, transitions = self._reconcile_individual(prior, {finding_id: representative})
                    events.extend(transitions)
        primary = aliases[0]
        participants = [channel for channel in CHANNELS if any(channel in entry['channels'] for entry in aliases)]
        records = {finding_id: dict(row, episode=episode, alert_alias=primary['alias'],
                                   alert_channels=list(participants), alert_member=membership[finding_id],
                                   alert_aliases=[dict(entry, channels=list(entry['channels'])) for entry in aliases])
                   for finding_id, row in effective.items()}
        return records, events

    def _reconcile_individual(self, previous, observed):
        records, events = {}, []
        for finding_id, fresh in observed.items():
            old = previous.get(finding_id)
            if old is None and not fresh['open']:
                continue
            episode = old['episode'] if old else 1
            # Preserve the actual existing alert identity on closure, including
            # records created before database generations were introduced.
            legacy_alias = f'dd:{self.policy["namespace"]}:{finding_id}:{episode}'
            record = dict(fresh, episode=episode,
                          alert_alias=(old.get('alert_alias') or legacy_alias) if old else None,
                          alert_channels=list(old.get('alert_channels', CHANNELS)) if old else list(self.channels))
            kind = None
            if fresh['open'] and (old is None or not old['open']):
                kind = 'new' if old is None else 'reopened'
                record['alert_channels'] = list(self.channels)
                if old is not None:
                    record['episode'] += 1
                record['alert_alias'] = (f'dd:{self.policy["namespace"]}:{self.generation}:'
                                         f'{finding_id}:{record["episode"]}')
            elif old and old['open'] and not fresh['open']:
                kind = 'resolved' if fresh['reason'] == 'fixed' else 'suppressed'
            records[finding_id] = record
            if kind is None:
                continue
            alias = record['alert_alias']
            transition = f'{alias}:{kind}'
            title = f'{kind.upper()} Critical — {clean(record["title"])}'
            text = (f'{title}\nEngagement: {clean(record["engagement_name"])}\nBranch: main\n'
                    f'Reason: {record["reason"]}\nDiscovered: {record["date"]}\n{record["url"]}')
            # Keep closures for an episode's original destinations durable while
            # they are disabled. Dispatch pauses them until the channel returns.
            channels = self.channels
            if kind in ('resolved', 'suppressed'):
                channels = tuple(channel for channel in CHANNELS
                                 if channel in self.channels or channel in record['alert_channels'])
            events.extend(self.events(transition, kind, alias, dict(
                alias=alias, title=title, text=text, finding_id=record['id'],
                engagement_id=record['engagement_id'], finding=dict(
                    id=record['id'], title=clean(record['title']),
                    project=clean(record['engagement_name']), branch='main',
                    severity=record.get('severity', 'Critical'), reason=record['reason'],
                    discovered=record['date'], url=record['url'])), channels=channels))
        return records, events

    def daily_events(self, engagement_id, records, recent):
        local_now = self.now.astimezone(ZoneInfo(self.policy['time_zone']))
        local_date = local_now.date()
        records = sorted(records, key=lambda r: (r['date'], r['id']))
        new = {e['payload']['finding_id'] for e in recent
               if e['kind'] in ('new', 'reopened')
               and e['payload'].get('engagement_id') == engagement_id}
        fixed = {e['payload']['finding_id'] for e in recent
                 if e['kind'] == 'resolved' and e['payload'].get('engagement_id') == engagement_id}
        name = clean(records[0]['engagement_name'])
        header = (f'Critical findings — {name}\nEngagement ID: {engagement_id}\nBranch: main\n'
                  f'Date: {local_date}\nOpen: {len(records)}\nNew in 24h: {len(new)}\n'
                  f'Fixed in 24h: {len(fixed)}\n')
        lines = []
        for number, record in enumerate(records, 1):
            age = max(0, (local_date - date.fromisoformat(record['date'])).days)
            # Long scanner titles are wrapped into multiple lines, never silently omitted.
            title = clean(record['title'])
            pieces = [title[n:n + 1000] for n in range(0, len(title), 1000)] or ['']
            lines.append(f'{number}. {pieces[0]} — {age} days\n')
            lines.extend(f'   {piece}\n' for piece in pieces[1:])
            lines.append(record['url'] + '\n')
        parts, body = [], ''
        # Reserve room for largest header and numbered-part suffix.
        available = 3000 - len(header) - 80
        if available < 1000:
            raise SourceError('summary_header_budget')
        for line in lines:
            if len(body) + len(line) > available:
                parts.append(body)
                body = ''
            body += line
        if body:
            parts.append(body)
        events = []
        for index, body in enumerate(parts, 1):
            alias = f'dd:{self.policy["namespace"]}:{self.generation}:digest:{engagement_id}:{local_date}:{index}'
            title = f'Critical summary — {name} — {local_date} ({index}/{len(parts)})'
            text = header + f'Part: {index}/{len(parts)}\n\n' + body
            for channel in self.channels:
                payload = dict(alias=alias, title=title, text=text, engagement_id=engagement_id)
                if channel in ('slack', 'opsgenie'):
                    if index != 1:
                        continue
                    # Summary links are built from configured DefectDojo origin,
                    # never from scanner titles or a finding's imported URL.
                    origin = origin_url(self.policy.get('api_url') or self.source.api.origin)
                    payload['summary'] = dict(
                        project=name, branch='main', engagement_id=engagement_id,
                        report_date=local_date.isoformat(), open_count=len(records),
                        new_count=len(new), fixed_count=len(fixed),
                        url=f'{origin}/engagement/{engagement_id}',
                        findings=[dict(id=record['id'], title=clean(record['title']),
                                       age_days=max(0, (local_date - date.fromisoformat(record['date'])).days),
                                       url=f'{origin}/finding/{record["id"]}') for record in records[:5]])
                    payload['text'] = (f'Critical Findings Summary — {name} | {len(records)} Open | '
                                       f'{len(new)} New | {len(fixed)} Fixed')
                    if channel == 'opsgenie':
                        payload['title'] = payload['text']
                        payload['text'] = opsgenie_summary(payload['summary'])
                events.extend(self.events(alias, 'digest', alias, payload, channels=(channel,)))
        return local_date, events

    def dispatch(self):
        from .delivery import DeliveryError
        delivered, deferred, handled = 0, 0, set()
        started = time.monotonic()
        while len(handled) < 300 and time.monotonic() - started < 600:
            pending = [e for e in self.store.pending(self.now, limit=100, channels=self.channels) if e['id'] not in handled]
            if not pending:
                break
            for event in pending:
                if len(handled) >= 300 or time.monotonic() - started >= 600:
                    break
                handled.add(event['id'])
                try:
                    outcome = self.sender.send(event)
                    if outcome.get('status') == 'pending':
                        self.store.defer(event['id'], self.now + timedelta(seconds=60),
                                         'provider_processing', request_id=outcome['request_id'])
                        deferred += 1
                    elif outcome.get('status') == 'delivered':
                        self.store.delivered(event['id'], remote_id=outcome.get('remote_id'))
                        delivered += 1
                    else:
                        raise DeliveryError('invalid_delivery_result')
                except DeliveryError as error:
                    delay = min(3600, 60 * (2 ** min(event['attempts'], 6)))
                    retry_after = getattr(error, 'retry_after', None)
                    if retry_after is not None:
                        delay = max(delay, min(86400, max(0, retry_after)))
                    self.store.defer(event['id'], self.now + timedelta(seconds=delay), error.code,
                                     clear_request=getattr(error, 'clear_request', False))
                    deferred += 1
        return dict(delivered=delivered, deferred=deferred)

    def run(self, mode):
        if mode not in ('poll', 'digest'):
            raise ValueError('invalid_mode')
        self.generation = self.store.generation()
        previous = self.store.load_findings()
        try:
            observed, blocked = self.source.collect(previous)
        except SourceError as error:
            # Collection has no durable writes. Previously committed deliveries
            # can still progress under the caller's lock during a source outage.
            error.details = dict(error.details, **self.dispatch())
            raise
        records, events = self.reconcile(previous, observed)
        summary = dict(mode=mode, observed=len(observed),
                       blocked_engagements=len(blocked), blocked_engagement_ids=sorted(blocked))
        if mode == 'poll':
            summary['lifecycle_events'] = len({event['payload']['transition_id'] for event in events})
            summary['finding_ids'] = sorted(int(k) for k, r in records.items() if r['open'])
            changed = {finding_id: record for finding_id, record in records.items()
                       if record != previous.get(finding_id)}
            self.store.snapshot(changed, events)
        else:
            # A daily list must be complete. Do not turn a partial source into a reassuring report.
            groups = defaultdict(list)
            for record in observed.values():
                if record['open'] and record['engagement_id'] not in blocked:
                    groups[record['engagement_id']].append(record)
            recent = self.store.recent_events(self.now - timedelta(hours=24))
            summary['engagement_ids'] = sorted(groups)
            for engagement_id, rows in groups.items():
                local_date, digest_events = self.daily_events(engagement_id, rows, recent)
                self.store.enqueue_digest(local_date, engagement_id, digest_events)
        summary.update(self.dispatch())
        if mode == 'digest' and blocked:
            raise SourceError('summary_source_unconfirmed', {'blocked_engagement_ids': sorted(blocked)})
        return summary
