"""Behavioral contracts for Critical main-branch reconciliation and daily lists."""
import copy
import sys
import unittest
from datetime import datetime, timedelta, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'notifier'))
try:
    from notifier.source import Source, SourceError
    from notifier.engine import Engine
except ImportError:
    Source = Engine = None

NOW = datetime(2026, 11, 12, 9, 0, tzinfo=timezone.utc)
OLD = '2026-11-01T08:00:00Z'


def test_row(id=10, engagement=1, **changes):
    return dict(id=id, engagement=engagement, title='Trivy: example-api [ref:branch:main]',
                test_type_name='Trivy Scan', branch_tag='main', percent_complete=100,
                updated=OLD, **changes)


# This imported fixture factory must not be collected as a pytest test.
test_row.__test__ = False


def finding(id=1, test=10, **changes):
    row = dict(id=id, test=test, title=f'Finding {id}', date='2026-11-05', severity='Critical',
               active=True, duplicate=False, false_p=False, out_of_scope=False,
               risk_accepted=False, mitigated=None)
    row.update(changes)
    return row


class FakeAPI:
    origin = 'https://dojo.example.com'
    def __init__(self):
        self.engagements = {1: {'id': 1, 'name': 'Example', 'product': 5}}
        self.tests = {10: test_row()}
        self.findings = {1: finding()}
        self.calls = []
        self.truncate = False
        self.change_test = False

    def get(self, path, params=None, missing_ok=False):
        self.calls.append((path, params))
        kind, _, object_id = path.rstrip('/').partition('/')
        rows = {'engagements': self.engagements, 'tests': self.tests, 'findings': self.findings}
        if kind == 'test_imports':
            items = [dict(id=100, test=params['test'], type='reimport', branch_tag='main',
                          created=OLD, modified=OLD)]
        elif object_id:
            result = copy.deepcopy(rows[kind].get(int(object_id)))
            if kind == 'tests' and self.change_test:
                self.tests[int(object_id)]['updated'] = '2026-11-12T08:59:59Z'
            return result
        else:
            items = list(rows[kind].values())
            if params:
                for key in ('engagement', 'test', 'severity'):
                    if key in params:
                        items = [r for r in items if r[key] == params[key]]
                if params.get('active') == 'true':
                    items = [r for r in items if r['active'] is True]
                if 'id' in params:
                    ids = {int(value) for value in str(params['id']).split(',')}
                    items = [r for r in items if r['id'] in ids]
        offset, limit = (params or {}).get('offset', 0), (params or {}).get('limit', 50)
        result = copy.deepcopy(items[offset:offset + limit])
        if self.truncate and kind == 'findings':
            return {'count': len(items) + 1, 'results': result, 'next': None}
        return {'count': len(items), 'results': result,
                'next': 'next' if offset + len(result) < len(items) else None}


class MemoryStore:
    def __init__(self):
        self.records = {}
        self.events = []
        self.manifests = set()
        self.calls = []
        self.broken = False
        self.generation_id = "a" * 32
    def generation(self): return self.generation_id
    def load_findings(self): return copy.deepcopy(self.records)
    def snapshot(self, records, events):
        if self.broken: raise RuntimeError('db unavailable')
        self.calls.append('snapshot')
        self.records.update(copy.deepcopy(records))
        self.enqueue(events)
    def enqueue(self, events):
        for event in events:
            if not any(e['event_key'] == event['event_key'] for e in self.events):
                self.events.append(dict(copy.deepcopy(event), id=len(self.events) + 1,
                                        attempts=0, request_id=None, status='pending'))
    def enqueue_digest(self, date, engagement_id, events):
        key = (str(date), engagement_id)
        if key not in self.manifests:
            self.manifests.add(key)
            self.enqueue(events)
    def recent_events(self, since):
        distinct = {}
        for event in self.events:
            if event['created_at'] >= since:
                distinct[event['payload']['transition_id']] = copy.deepcopy(event)
        return list(distinct.values())
    def pending(self, now, limit=100, channels=None):
        result = []
        for event in self.events:
            earlier = any(e['id'] < event['id'] and e['status'] == 'pending'
                          and e['channel'] == event['channel'] and e['stream'] == event['stream']
                          for e in self.events)
            if (event['status'] == 'pending' and event.get('next_attempt', now) <= now and not earlier
                    and (channels is None or event['channel'] in channels)):
                result.append(copy.deepcopy(event))
        return result[:limit]
    def delivered(self, id, remote_id=None):
        self.events[id-1]['status'] = 'delivered'
    def defer(self, id, next_attempt, error_code, request_id=None, clear_request=False):
        event = self.events[id-1]
        event.update(attempts=event['attempts'] + 1, next_attempt=next_attempt)
        if clear_request: event['request_id'] = None
        elif request_id is not None: event['request_id'] = request_id


class Sender:
    def __init__(self): self.calls = []; self.failed = set()
    def send(self, event):
        self.calls.append(copy.deepcopy(event))
        if event['channel'] in self.failed:
            from notifier.delivery import DeliveryError
            raise DeliveryError('temporary_failure')
        return {'status': 'delivered'}


class NotificationTests(unittest.TestCase):
    def setUp(self):
        self.assertIsNotNone(Source, 'Critical source/engine are not implemented yet')
        self.api, self.store, self.sender = FakeAPI(), MemoryStore(), Sender()
        self.policy = dict(namespace='example', api_url=self.api.origin, engagement_ids=[1],
                           all_engagements=False, time_zone='Asia/Yerevan')
        self.engine = Engine(Source(self.api, self.policy, now=NOW), self.store,
                             self.sender, self.policy, now=NOW)

    def poll(self): return self.engine.run('poll')
    def digest(self): return self.engine.run('digest')

    def test_lifecycle_payload_contains_structured_finding_card_data(self):
        title = 'CVE-2026-56367 libmagickwand-6.q16-6 8:6.9.11.60+dfsg-1.3+deb11u5'
        self.api.findings[1]['title'] = title
        self.api.engagements[1]['name'] = 'Example\nAPI'
        self.poll()
        for event in self.sender.calls:
            self.assertEqual(event['payload'].get('finding'), {
                'id': 1, 'title': title, 'project': 'Example API', 'branch': 'main',
                'severity': 'Critical', 'reason': 'open', 'discovered': '2026-11-05',
                'url': 'https://dojo.example.com/finding/1',
            })
            self.assertIn(title, event['payload']['text'])
        self.assertEqual(self.store.records['1'].get('severity'), 'Critical')

    def test_suppressed_card_reports_actual_changed_severity_and_existing_alias(self):
        self.poll()
        alias = self.sender.calls[0]['payload']['alias']
        self.api.findings[1]['severity'] = 'High'
        self.sender.calls.clear()
        self.poll()
        self.assertEqual(len(self.sender.calls), 3)
        for event in self.sender.calls:
            self.assertEqual(event['kind'], 'suppressed')
            self.assertEqual(event['payload']['alias'], alias)
            self.assertEqual(event['payload'].get('finding', {}).get('severity'), 'High')
            self.assertEqual(event['payload'].get('finding', {}).get('reason'), 'severity_changed')
            self.assertIn('Reason: severity_changed', event['payload']['text'])

    def test_card_metadata_upgrade_does_not_resend_existing_findings(self):
        self.poll()
        original_keys = {event['event_key'] for event in self.store.events}
        self.store.records['1'].pop('severity')
        for event in self.store.events:
            event['payload'].pop('finding')
        self.poll()
        self.assertEqual(len(self.sender.calls), 3)
        self.assertEqual({event['event_key'] for event in self.store.events}, original_keys)
        self.assertEqual(self.store.records['1']['severity'], 'Critical')

    def test_six_then_one_creates_seven_messages_per_channel(self):
        self.api.findings = {i: finding(i) for i in range(1, 7)}
        self.poll()
        self.assertEqual(len(self.sender.calls), 18)
        self.poll()
        self.assertEqual(len(self.sender.calls), 18)
        self.api.findings[7] = finding(7)
        self.poll()
        self.assertEqual(len(self.sender.calls), 21)
        self.assertEqual([e['payload']['finding_id'] for e in self.sender.calls[-3:]], [7, 7, 7])

    def test_purged_database_resends_with_new_remote_alert_identity(self):
        self.poll()
        original = next(e['payload']['alias'] for e in self.sender.calls if e['channel'] == 'opsgenie')
        self.store = MemoryStore()
        self.store.generation_id = 'b' * 32
        self.engine.store = self.store
        self.sender.calls.clear()
        self.poll()
        self.assertEqual(len(self.sender.calls), 3)
        replacement = next(e['payload']['alias'] for e in self.sender.calls if e['channel'] == 'opsgenie')
        self.assertNotEqual(original, replacement)

    def test_purged_database_daily_summary_has_new_identity_on_same_day(self):
        self.digest()
        original = self.sender.calls[-1]['payload']['alias']
        self.store = MemoryStore()
        self.store.generation_id = 'b' * 32
        self.engine.store = self.store
        self.sender.calls.clear()
        self.digest()
        self.assertEqual(len(self.sender.calls), 3)
        self.assertNotEqual(original, self.sender.calls[-1]['payload']['alias'])

    def test_retained_database_preserves_alias_across_process_restart(self):
        self.poll()
        original = self.sender.calls[-1]['payload']['alias']
        self.sender.calls.clear()
        self.engine = Engine(Source(self.api, self.policy, now=NOW), self.store,
                             self.sender, self.policy, now=NOW)
        self.poll()
        self.assertEqual(self.sender.calls, [])
        self.api.findings[1].update(active=False, mitigated='2026-11-12T08:00:00Z')
        self.poll()
        self.assertTrue(all(e['payload']['alias'] == original for e in self.sender.calls))

    def test_legacy_open_record_closes_its_legacy_alias_after_schema_upgrade(self):
        self.poll()
        legacy = f'dd:{self.policy["namespace"]}:1:1'
        self.store.records['1'].pop('alert_alias', None)
        self.sender.calls.clear()
        self.api.findings[1].update(active=False, mitigated='2026-11-12T08:00:00Z')
        self.poll()
        self.assertEqual(len(self.sender.calls), 3)
        self.assertTrue(all(e['payload']['alias'] == legacy for e in self.sender.calls))
        self.api.findings[1].update(active=True, mitigated=None)
        self.sender.calls.clear()
        self.poll()
        self.assertEqual(len(self.sender.calls), 3)
        self.assertTrue(all(e['payload']['alias'] != legacy for e in self.sender.calls))

    def test_generation_aliases_fit_sql_stream_limit_at_maximum_ids(self):
        maximum = 9223372036854775807
        self.policy['namespace'] = 'f' * 64
        self.policy['engagement_ids'] = [maximum]
        self.api.engagements = {maximum: dict(id=maximum, name='Example', product=5)}
        self.api.tests[10]['engagement'] = maximum
        self.api.findings = {maximum: finding(maximum)}
        self.poll()
        self.digest()
        self.assertTrue(self.store.events)
        self.assertTrue(all(len(e['stream']) <= 160 for e in self.store.events))

    def test_exact_branch_and_type_only(self):
        for title, branch, type_name in [
            ('Trivy: example-api [ref:branch:main-old]', 'main-old', 'Trivy Scan'),
            ('Trivy: example-api [ref:tag:main]', 'main', 'Trivy Scan'),
            ('Trivy: example-api [ref:branch:main] trailing', 'main', 'Trivy Scan'),
            ('Trivy: example-api [ref:branch:main]', 'feature/a', 'Trivy Scan'),
            ('Trivy: example-api [ref:branch:main]', 'main', 'Other Scan')]:
            self.api.tests[10].update(title=title, branch_tag=branch, test_type_name=type_name)
            self.poll()
        self.assertEqual(self.sender.calls, [])

    def test_optional_environment_allowed(self):
        self.api.tests[10]['title'] += ' [env:staging]'
        self.poll()
        self.assertEqual(len(self.sender.calls), 3)

    def test_each_exclusion_suppresses_initial_finding(self):
        for flag in ['duplicate', 'false_p', 'out_of_scope', 'risk_accepted']:
            self.api.findings[1] = finding(**{flag: True})
            self.poll()
        self.assertEqual(self.sender.calls, [])

    def test_unverified_finding_is_included(self):
        self.api.findings[1]['verified'] = False
        self.poll()
        self.assertEqual(len(self.sender.calls), 3)

    def test_promotion_then_resolution_then_reopening(self):
        self.api.findings[1]['severity'] = 'High'
        self.poll()
        self.assertEqual(self.sender.calls, [])
        self.api.findings[1]['severity'] = 'Critical'
        self.poll()
        first_alias = self.sender.calls[0]['payload']['alias']
        self.api.findings[1].update(active=False, mitigated='2026-11-12T08:00:00Z')
        self.poll()
        self.assertEqual([e['kind'] for e in self.sender.calls[-3:]], ['resolved'] * 3)
        self.api.findings[1].update(active=True, mitigated=None)
        self.poll()
        self.assertEqual([e['kind'] for e in self.sender.calls[-3:]], ['reopened'] * 3)
        self.assertNotEqual(first_alias, self.sender.calls[-1]['payload']['alias'])

    def test_exclusion_closes_with_reason_not_fixed(self):
        self.poll()
        self.api.findings[1].update(active=False, false_p=True, mitigated='2026-11-12T08:00:00Z')
        self.poll()
        self.assertEqual(self.sender.calls[-1]['kind'], 'suppressed')
        self.assertIn('false_positive', self.sender.calls[-1]['payload']['text'])

    def test_missing_finding_is_never_fixed(self):
        self.poll()
        del self.api.findings[1]
        self.poll()
        self.assertEqual(len(self.sender.calls), 3)
        self.assertTrue(self.store.records['1']['open'])

    def test_partial_source_cannot_commit_or_send(self):
        self.api.truncate = True
        with self.assertRaises(SourceError): self.poll()
        self.assertEqual(self.store.records, {})
        self.assertEqual(self.sender.calls, [])

    def test_processing_or_changed_test_does_not_emit(self):
        for changes in [dict(percent_complete=20), dict(processing=True),
                        dict(status='Post Processing - Deduplication')]:
            self.api.tests[10] = test_row()
            self.api.tests[10].update(changes)
            self.poll()
        self.api.tests[10] = test_row()
        self.api.change_test = True
        self.poll()
        self.assertEqual(self.sender.calls, [])

    def test_missing_required_boolean_fails_closed(self):
        del self.api.findings[1]['risk_accepted']
        with self.assertRaises(SourceError): self.poll()
        self.assertEqual(self.sender.calls, [])

    def test_moved_tracked_finding_is_preserved_and_other_findings_deliver(self):
        self.poll()
        self.api.findings[1]['test'] = 999
        self.api.findings[2] = finding(2)
        self.poll()
        self.assertEqual(len(self.sender.calls), 6)
        self.assertTrue(self.store.records['1']['open'])
        self.assertEqual(self.store.records['1']['test_id'], 10)

    def test_cross_scope_list_response_still_fails_closed(self):
        get = self.api.get
        def wrong_list(path, params=None, missing_ok=False):
            result = get(path, params, missing_ok)
            if path == 'findings/' and result['results']:
                result['results'][0]['test'] = 999
            return result
        self.api.get = wrong_list
        with self.assertRaises(SourceError): self.poll()
        self.assertEqual(self.sender.calls, [])

    def test_supported_test_api_ordering(self):
        # ApiTestFilter from pinned DefectDojo3.4.304 supports created, not id.
        get = self.api.get
        def official_filter(path, params=None, missing_ok=False):
            if path == 'tests/' and (params or {}).get('o') not in (None, 'created', 'updated'):
                raise SourceError('api_http_400')
            return get(path, params, missing_ok)
        self.api.get = official_filter
        self.poll()
        self.assertEqual(len(self.sender.calls), 3)

    def test_deleted_selected_engagement_does_not_block_healthy_findings(self):
        self.api.engagements[2] = dict(id=2, name='Other', product=5)
        self.api.tests[20] = test_row(20, 2)
        self.api.findings[2] = finding(2, 20)
        self.policy['engagement_ids'] = [1, 2]
        self.poll()
        self.sender.calls.clear()
        del self.api.engagements[1]
        self.api.findings[3] = finding(3, 20)
        self.poll()
        self.assertEqual(len(self.sender.calls), 3)
        with self.assertRaises(SourceError): self.digest()
        self.assertEqual(len([e for e in self.sender.calls if e['kind'] == 'digest']), 3)

    def test_database_failure_never_sends(self):
        self.store.broken = True
        with self.assertRaises(RuntimeError): self.poll()
        self.assertEqual(self.sender.calls, [])

    def test_channel_failure_does_not_repeat_successful_channels(self):
        self.sender.failed = {'teams'}
        self.poll()
        self.assertEqual(len(self.sender.calls), 3)
        self.sender.failed = set()
        self.engine.now += timedelta(minutes=15)
        self.poll()
        self.assertEqual(len(self.sender.calls), 4)
        self.assertEqual(self.sender.calls[-1]['channel'], 'teams')

    def test_invoked_worker_always_persists_and_delivers_with_database_generation(self):
        poll = self.poll()
        self.assertEqual(self.store.calls, ['snapshot'])
        self.assertEqual(len(self.sender.calls), 3)
        self.assertEqual(poll['delivered'], 3)
        self.assertNotIn('dry_run', poll)
        self.assertTrue(all(f':{self.store.generation_id}:' in e['payload']['alias']
                            for e in self.sender.calls))
        digest = self.digest()
        self.assertEqual(self.store.manifests, {(str(NOW.date()), 1)})
        self.assertEqual(len(self.sender.calls), 6)
        self.assertEqual(digest['delivered'], 3)
        self.assertNotIn('dry_run', digest)

    def test_digest_per_engagement_with_ages_and_no_duplicate(self):
        self.api.engagements[2] = dict(id=2, name='Other', product=5)
        self.api.tests[20] = test_row(20, 2)
        self.api.findings[2] = finding(2, 20, date='2026-11-01')
        self.policy['engagement_ids'] = [1, 2]
        self.poll()
        self.sender.calls.clear()
        self.digest()
        digests = [e for e in self.sender.calls if e['kind'] == 'digest']
        self.assertEqual(len(digests), 6)
        for event in digests:
            if event['channel'] == 'slack':
                self.assertEqual(len(event['payload']['summary']['findings']), 1)
                continue
            self.assertIn('Finding', event['payload']['text'])
            self.assertIn('days', event['payload']['text'])
            self.assertIn('https://dojo.example.com/finding/', event['payload']['text'])
        self.digest()
        self.assertEqual(len(self.sender.calls), 6)

    def test_same_day_changed_inventory_does_not_append_digest_parts(self):
        self.digest()
        self.api.findings.update({i: finding(i, title='x' * 500) for i in range(2, 40)})
        self.digest()
        self.assertEqual(len([e for e in self.sender.calls if e['kind'] == 'digest']), 3)

    def test_digest_chunking_keeps_every_finding(self):
        self.api.findings = {i: finding(i, title=f'UNIQUE-{i}: ' + 'x' * 100) for i in range(1, 90)}
        self.digest()
        for channel in ('teams', 'opsgenie'):
            texts = [e['payload']['text'] for e in self.sender.calls if e['channel'] == channel]
            self.assertGreater(len(texts), 1)
            self.assertTrue(all(len(s) <= 3000 for s in texts))
            for i in range(1, 90):
                self.assertEqual(sum(s.count(f'UNIQUE-{i}:') for s in texts), 1)

    def test_large_digest_has_one_slack_snapshot_and_complete_other_destinations(self):
        self.api.findings = {i: finding(i, title=f'UNIQUE-{i}: ' + 'x' * 100,
                                        date='2026-11-01' if i >= 210 else '2026-11-05')
                             for i in range(1, 221)}
        self.poll()
        self.api.findings[1].update(active=False, mitigated='2026-11-12T08:00:00Z')
        self.poll()
        self.sender.calls.clear()
        self.digest()
        slack = [e for e in self.sender.calls if e['channel'] == 'slack' and e['kind'] == 'digest']
        self.assertEqual(len(slack), 1)
        event = slack[0]
        self.assertTrue(event['payload']['alias'].endswith(':digest:1:2026-11-12:1'))
        self.assertEqual(event['payload']['summary'], {
            'project': 'Example', 'branch': 'main', 'engagement_id': 1,
            'report_date': '2026-11-12', 'open_count': 219, 'new_count': 220, 'fixed_count': 1,
            'url': 'https://dojo.example.com/engagement/1',
            'findings': [dict(id=i, title=f'UNIQUE-{i}: ' + 'x' * 100, age_days=11,
                              url=f'https://dojo.example.com/finding/{i}') for i in range(210, 215)]})
        self.assertEqual(event['payload']['text'],
                         'Critical Findings Summary — Example | 219 Open | 220 New | 1 Fixed')
        for channel in ('teams', 'opsgenie'):
            texts = [e['payload']['text'] for e in self.sender.calls
                     if e['channel'] == channel and e['kind'] == 'digest']
            self.assertGreater(len(texts), 1)
            self.assertTrue(all('New in 24h: 220' in text and 'Fixed in 24h: 1' in text for text in texts))
            for i in range(2, 221):
                self.assertEqual(sum(text.count(f'UNIQUE-{i}:') for text in texts), 1)
        queued = copy.deepcopy([e for e in self.store.events if e['kind'] == 'digest'])
        self.api.findings[221] = finding(221)
        self.api.engagements[1]['name'] = 'Renamed'
        self.sender.calls.clear()
        self.digest()
        self.assertEqual(self.sender.calls, [])
        self.assertEqual([e for e in self.store.events if e['kind'] == 'digest'], queued)

    def test_digest_destination_combinations_keep_single_slack_and_frozen_manifest(self):
        for channels in (('slack',), ('teams',), ('opsgenie',), ('slack', 'teams'),
                         ('slack', 'opsgenie'), ('teams', 'opsgenie'), ('slack', 'teams', 'opsgenie')):
            with self.subTest(channels=channels):
                self.store, self.sender = MemoryStore(), Sender()
                self.api.findings = {i: finding(i, title=f'UNIQUE-{i}: ' + 'x' * 500) for i in range(1, 40)}
                self.engine = Engine(Source(self.api, self.policy, now=NOW), self.store,
                                     self.sender, self.policy, now=NOW, channels=channels)
                self.digest()
                self.assertEqual({e['channel'] for e in self.store.events}, set(channels))
                if 'slack' in channels:
                    self.assertEqual(sum(e['channel'] == 'slack' for e in self.store.events), 1)
                frozen = copy.deepcopy(self.store.events)
                self.engine.channels = ('slack', 'teams', 'opsgenie')
                self.digest()
                self.assertEqual(self.store.events, frozen)

    def test_digest_url_comes_from_policy_even_with_stub_source_and_untrusted_finding_url(self):
        self.engine.generation = self.store.generation()
        records = [dict(id=1, date='2026-11-05', title='Example', engagement_name='Example',
                        url='https://scanner.example.com/finding/1')]
        self.engine.source = object()
        _, events = self.engine.daily_events(1, records, [])
        summary = next(e for e in events if e['channel'] == 'slack')['payload']['summary']
        self.assertEqual(summary['url'], 'https://dojo.example.com/engagement/1')
        self.assertEqual(summary['findings'][0]['url'], 'https://dojo.example.com/finding/1')

    def test_digest_omits_empty_engagement(self):
        self.api.findings = {}
        self.digest()
        self.assertEqual(self.sender.calls, [])

    def test_pagination_collects_more_than_one_page(self):
        self.api.findings = {i: finding(i) for i in range(1, 64)}
        self.poll()
        self.assertEqual(len([e for e in self.store.events if e['kind'] == 'new']), 189)

    def test_daily_counts_use_distinct_logical_events(self):
        self.poll()
        self.digest()
        text = [e for e in self.sender.calls if e['kind'] == 'digest'][0]['payload']['text']
        self.assertIn('1 New', text)

    def test_unknown_open_finding_blocks_incomplete_daily_list(self):
        self.poll()
        del self.api.findings[1]
        with self.assertRaises(SourceError): self.digest()
        self.assertEqual(len(self.sender.calls), 3)

    def test_blocked_engagement_does_not_suppress_healthy_summary(self):
        self.api.engagements[2] = dict(id=2, name='Other', product=5)
        self.api.tests[20] = test_row(20, 2)
        self.api.findings[2] = finding(2, 20)
        self.policy['engagement_ids'] = [1, 2]
        self.poll()
        self.sender.calls.clear()
        del self.api.findings[1]
        with self.assertRaises(SourceError): self.digest()
        digests = [e for e in self.sender.calls if e['kind'] == 'digest']
        self.assertEqual(len(digests), 3)
        self.assertTrue(all(e['payload']['engagement_id'] == 2 for e in digests))

    def test_removed_engagement_does_not_block_remaining_summary(self):
        self.api.engagements[2] = dict(id=2, name='Other', product=5)
        self.api.tests[20] = test_row(20, 2)
        self.api.findings[2] = finding(2, 20)
        self.policy['engagement_ids'] = [1, 2]
        self.poll()
        self.sender.calls.clear()
        self.policy['engagement_ids'] = [2]
        self.digest()
        self.assertEqual(len(self.sender.calls), 3)
        self.assertTrue(all(e['payload']['engagement_id'] == 2 for e in self.sender.calls))

class ConfigTests(unittest.TestCase):
    def config_module(self):
        try:
            from notifier import config
        except ImportError:
            self.fail('runtime configuration is not implemented yet')
        return config

    def valid(self):
        return dict(namespace='a' * 64, api_url='https://dojo.example.com', engagement_ids=[1],
                    all_engagements=False, time_zone='Asia/Yerevan',
                    mysql=dict(host='mysql.example.com', port=3306, database='notifier', tls=True),
                    opsgenie_region='us', priority='P2')

    def test_policy_accepts_exactly_eight_fields_and_rejects_ambiguous_scope(self):
        config = self.config_module()
        for change in [dict(engagement_ids=[]), dict(all_engagements=True),
                       dict(time_zone='unknown/timezone'), dict(namespace='../../bad'),
                       dict(api_url='https://user:pass@example.com')]:
            p = self.valid(); p.update(change)
            with self.assertRaises(config.ConfigError): config.validate(p)
        self.assertEqual(config.validate(self.valid())['mysql']['port'], 3306)
        self.assertEqual(len(config.validate(self.valid())), 8)
        for value in (True, False, None, 'false'):
            with self.subTest(legacy_value=value), self.assertRaisesRegex(config.ConfigError, 'invalid_policy_keys'):
                config.validate(dict(self.valid(), dry_run=value))

    def test_secrets_are_not_returned_in_errors(self):
        import tempfile
        config = self.config_module()
        with tempfile.TemporaryDirectory() as directory:
            Path(directory, 'api-token').write_text('SECRET\nINJECTED')
            with self.assertRaises(config.ConfigError) as caught:
                config.api_token(directory)
            self.assertNotIn('SECRET', str(caught.exception))

    def test_secret_password_preserves_spaces(self):
        import tempfile
        config = self.config_module()
        with tempfile.TemporaryDirectory() as directory:
            Path(directory, 'mysql-password').write_text(' password with spaces \n')
            self.assertEqual(config.secret(directory, 'mysql-password'), ' password with spaces ')

class APITests(unittest.TestCase):
    def api(self, **kwargs):
        from notifier.source import API
        return API('https://dojo.example.com', 'token', **kwargs)

    def test_pagination_link_never_accepts_changed_host_path_or_scope(self):
        from notifier.source import SourceError
        api = self.api()
        params = {'test': 10, 'severity': 'Critical', 'limit': 50, 'offset': 0}
        valid = 'https://dojo.example.com/api/v2/findings/?test=10&severity=Critical&limit=50&offset=50'
        api.check_link(valid, 'findings/', params)
        for bad in [valid.replace('dojo.example.com', 'evil.example.com'),
                    valid.replace('findings/', 'tests/'), valid.replace('test=10', 'test=20'),
                    valid.replace('Critical', 'High'), valid + '#fragment']:
            with self.assertRaises(SourceError): api.check_link(bad, 'findings/', params)

    def test_pagination_equivalent_default_ports_are_accepted_in_both_directions(self):
        from notifier.source import API
        params = {'test': 10, 'limit': 50, 'offset': 0}
        for scheme, port in (('https', 443), ('http', 80)):
            bare = f'{scheme}://dojo.example.com'
            explicit = f'{bare}:{port}'
            for base, target in ((explicit, bare), (bare, explicit),
                                 (f'{bare}:00{port}', bare),
                                 (bare, f'{scheme.upper()}://DOJO.example.com:{port}')):
                with self.subTest(base=base, target=target):
                    API(base, 'token').check_link(
                        target + '/api/v2/findings/?test=10&limit=50&offset=50', 'findings/', params)
        API('https://dojo.example.com:8443', 'token').check_link(
            'https://dojo.example.com:8443/api/v2/findings/?test=10&limit=50&offset=50',
            'findings/', params)

    def test_paginated_api_accepts_canonical_next_but_only_requests_configured_base(self):
        import json
        from urllib.parse import parse_qs, urlsplit
        from notifier.source import API
        class Response:
            status = 200
            def __init__(self, body): self.body = json.dumps(body).encode()
            def __enter__(self): return self
            def __exit__(self, *args): pass
            def read(self, limit): return self.body[:limit]
        class Opener:
            def __init__(self, target): self.target, self.calls = target, []
            def open(self, request, timeout):
                self.calls.append(request.full_url)
                offset = int(parse_qs(urlsplit(request.full_url).query)['offset'][0])
                rows = [{'id': i} for i in range(1, 52)]
                return Response(dict(count=51, results=rows[offset:offset + 50],
                                     next=self.target + '/api/v2/findings/?test=10&limit=50&offset=50'
                                     if offset == 0 else None))
        for base, target in (('https://dojo.example.com:443', 'https://dojo.example.com'),
                             ('https://dojo.example.com', 'https://dojo.example.com:443'),
                             ('http://dojo.example.com:80', 'http://dojo.example.com'),
                             ('http://dojo.example.com', 'http://dojo.example.com:80')):
            with self.subTest(base=base):
                opener = Opener(target)
                api = API(base, 'token', opener=opener)
                rows = Source(api, {}).listing('findings/', {'test': 10})
                self.assertEqual([row['id'] for row in rows], list(range(1, 52)))
                self.assertEqual(len(opener.calls), 2)
                self.assertTrue(all(url.startswith(base + '/api/v2/findings/') for url in opener.calls))

    def test_pagination_port_normalization_keeps_origin_and_scope_guards(self):
        from notifier.source import API, SourceError
        params = {'test': 10, 'limit': 50, 'offset': 0}
        suffix = '/api/v2/findings/?test=10&limit=50&offset=50'
        api = API('https://dojo.example.com:443', 'token')
        for target in ('https://evil.example.com', 'http://dojo.example.com',
                       'https://dojo.example.com:8443', 'https://dojo.example.com:0',
                       'https://dojo.example.com:65536', 'https://u:p@dojo.example.com',
                       'https://@dojo.example.com', '//dojo.example.com'):
            with self.subTest(target=target), self.assertRaises(SourceError):
                api.check_link(target + suffix, 'findings/', params)
        for link in ('https://dojo.example.com' + suffix.replace('test=10', 'test=20'),
                     'https://dojo.example.com' + suffix.replace('findings/', 'tests/'),
                     'https://dojo.example.com' + suffix + '#fragment'):
            with self.subTest(link=link), self.assertRaises(SourceError):
                api.check_link(link, 'findings/', params)
        with self.assertRaises(SourceError):
            API('https://dojo.example.com:8443', 'token').check_link(
                'https://dojo.example.com' + suffix, 'findings/', params)

    def test_api_does_not_expose_error_body_or_token(self):
        import io
        from urllib.error import HTTPError
        from notifier.source import SourceError
        class Opener:
            def open(self, request, timeout):
                raise HTTPError(request.full_url, 403, 'SECRET body', {}, io.BytesIO(b'SECRET'))
        with self.assertRaises(SourceError) as caught: self.api(opener=Opener()).get('findings/')
        self.assertEqual(str(caught.exception), 'api_http_403')
        self.assertNotIn('SECRET', str(caught.exception))

    def test_api_404_requires_explicit_missing_ok(self):
        import io
        from urllib.error import HTTPError
        from notifier.source import SourceError
        class Opener:
            def open(self, request, timeout):
                raise HTTPError(request.full_url, 404, '', {}, io.BytesIO(b''))
        self.assertIsNone(self.api(opener=Opener()).get('findings/1/', missing_ok=True))
        with self.assertRaises(SourceError): self.api(opener=Opener()).get('findings/1/')


class CLITests(unittest.TestCase):
    def test_legacy_preview_policy_is_rejected_before_any_credentials_or_external_calls(self):
        import io
        import json
        import os
        import tempfile
        from contextlib import redirect_stdout
        from unittest.mock import patch
        from notifier.__main__ import main
        for mode in ('poll', 'digest', 'init-db'):
            for value in (True, False):
                with self.subTest(mode=mode, legacy_value=value), tempfile.TemporaryDirectory() as directory:
                    policy = dict(ConfigTests().valid(), dry_run=value)
                    policy_file = Path(directory, 'policy.json')
                    policy_file.write_text(json.dumps(policy))
                    with patch.dict(os.environ, POLICY_FILE=str(policy_file), SECRET_DIR=directory), \
                            patch('notifier.config.secret', return_value='credential') as secret, \
                            patch('notifier.config.api_token', return_value='token') as token, \
                            patch('notifier.config.channel_secrets', return_value=({'slack-url': 'https://hooks.example.com/slack'}, ('slack',))) as channels, \
                            patch('notifier.__main__.MySQLStore.connect') as connect, \
                            patch('notifier.__main__.API') as api, \
                            patch('notifier.__main__.Engine') as engine, \
                            patch('notifier.delivery.Sender') as sender, \
                            redirect_stdout(io.StringIO()) as output:
                        engine.return_value.run.return_value = {'mode': mode}
                        self.assertEqual(main([mode]), 1, output.getvalue())
                        self.assertEqual(json.loads(output.getvalue()), {'reason': 'invalid_policy_keys'})
                    for external in (secret, token, channels, connect, api, engine, sender):
                        external.assert_not_called()

    def test_invalid_command_does_not_print_secrets(self):
        import io
        from contextlib import redirect_stdout
        from notifier.__main__ import main
        with redirect_stdout(io.StringIO()) as output:
            self.assertEqual(main(['SECRET']), 1)
        self.assertNotIn('SECRET', output.getvalue())


if __name__ == '__main__':
    unittest.main()
