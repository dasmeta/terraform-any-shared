"""Slack finding cards with literal scanner values and a legacy text fallback."""
from datetime import date
import json
import re
import unicodedata
from urllib.parse import urlsplit


SEVERITIES = {'Critical': ('🔴', '#DC2626'), 'High': ('🟠', '#EA580C'),
              'Medium': ('🟡', '#CA8A04'), 'Low': ('🔵', '#2563EB'), 'Info': ('⚪', '#6B7280')}
REASONS = {'open', 'fixed', 'false_positive', 'duplicate', 'out_of_scope',
           'risk_accepted', 'inactive', 'severity_changed'}
# Only conventional CVE/package/version titles are reformatted. No text parsing of
# the legacy message is used to recover missing structured metadata.
CVE_TITLE = re.compile(r'(CVE-[0-9]{4}-[0-9]{4,}) (?:in )?([A-Za-z0-9@][A-Za-z0-9@./_:+~\-]* [vV]?[0-9][^\s]*)')
MARKUP = re.compile(r'[*_~`\[\]\\\r\n]')


def escape(value):
    return value.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')


def _valid(finding, kind):
    if not isinstance(finding, dict) or kind not in ('new', 'reopened', 'resolved', 'suppressed'):
        return False
    if type(finding.get('id')) is not int or finding['id'] <= 0:
        return False
    if any(not isinstance(finding.get(key), str) or not finding[key]
           for key in ('title', 'project', 'branch', 'severity', 'reason', 'discovered', 'url')):
        return False
    if (finding['severity'] not in SEVERITIES or finding['reason'] not in REASONS
            or finding['branch'] != 'main'):
        return False
    if ((kind in ('new', 'reopened') and finding['reason'] != 'open')
            or (kind == 'resolved' and finding['reason'] != 'fixed')
            or (kind == 'suppressed' and finding['reason'] in ('open', 'fixed'))):
        return False
    try:
        if date.fromisoformat(finding['discovered']).isoformat() != finding['discovered']:
            return False
        url = finding['url']
        if len(url) > 3000 or '\\' in url or any(c.isspace() or unicodedata.category(c) == 'Cc' for c in url):
            return False
        parts = urlsplit(url)
        if (parts.scheme not in ('http', 'https') or not parts.hostname
                or parts.username is not None or parts.password is not None
                or parts.query or parts.fragment or '?' in url or '#' in url
                or parts.path != f'/finding/{finding["id"]}'):
            return False
        if parts.port == 0:
            return False
    except (ValueError, TypeError):
        return False
    return True


def _plain(text):
    # Explicitly disable emoji conversion in untrusted scanner/Engagement text.
    return {'type': 'plain_text', 'text': text, 'emoji': False}


def _markdown(text):
    return {'type': 'mrkdwn', 'text': text, 'verbatim': True}


def _sections(value):
    """Keep all text and complete escape entities inside Slack's 3000-char limit."""
    chunks, current, size = [], [], 0
    for char in value:
        escaped = escape(char)
        if size + len(escaped) > 3000:
            chunks.append(''.join(current))
            current, size = [], 0
        current.append(escaped)
        size += len(escaped)
    if current:
        chunks.append(''.join(current))
    return [{'type': 'section', 'text': _plain(chunk)} for chunk in chunks]


def _summary_origin(url, path):
    """Validate canonical DefectDojo links before using Slack's link syntax."""
    if (not isinstance(url, str) or len(url) > 3000 or
            any(c.isspace() or unicodedata.category(c) == 'Cc' or c in '\\%<>&|?#' for c in url)):
        return None
    try:
        parts = urlsplit(url)
        if (parts.scheme not in ('http', 'https') or not parts.hostname
                or parts.username is not None or parts.password is not None
                or parts.port == 0 or parts.netloc.endswith(':')
                or parts.path != path or parts.query or parts.fragment):
            return None
        origin = f'{parts.scheme}://{parts.netloc}'
        return origin if url == origin + path else None
    except ValueError:
        return None


def _valid_summary(summary):
    if not isinstance(summary, dict):
        return False
    if (not isinstance(summary.get('project'), str) or not summary['project']
            or summary.get('branch') != 'main'
            or type(summary.get('engagement_id')) is not int or summary['engagement_id'] <= 0):
        return False
    if any(type(summary.get(key)) is not int or summary[key] < 0
           for key in ('open_count', 'new_count', 'fixed_count')):
        return False
    try:
        if date.fromisoformat(summary['report_date']).isoformat() != summary['report_date']:
            return False
    except (KeyError, ValueError, TypeError):
        return False
    origin = _summary_origin(summary.get('url'), f'/engagement/{summary["engagement_id"]}')
    findings = summary.get('findings')
    if (not origin or not isinstance(findings, list)
            or len(findings) > min(5, summary['open_count'])):
        return False
    seen = set()
    for finding in findings:
        if (not isinstance(finding, dict) or type(finding.get('id')) is not int or finding['id'] <= 0
                or finding['id'] in seen or not isinstance(finding.get('title'), str) or not finding['title']
                or type(finding.get('age_days')) is not int or finding['age_days'] < 0
                or _summary_origin(finding.get('url'), f'/finding/{finding["id"]}') != origin):
            return False
        seen.add(finding['id'])
    return True


def _sample_sections(finding):
    title, url, age = finding['title'], finding['url'], finding['age_days']
    match = CVE_TITLE.fullmatch(title)
    if match and not MARKUP.search(title):
        formatted = f'🔴 *<{url}|{match[1]}>*\n`{escape(match[2])}` · {age} days'
        if len(formatted) <= 3000:
            return [{'type': 'section', 'text': _markdown(formatted)}]
    # Keep unconventional (or very long) source titles entirely literal. Only the
    # separately constructed DefectDojo link is interpreted as Slack markup.
    return _sections(title) + [{'type': 'section', 'text': _markdown(
        f'🔴 <{url}|View Finding #{finding["id"]}> · {age} days')}]


def _summary_message(body, text, summary):
    blocks = [{'type': 'header', 'text': {'type': 'plain_text',
               'text': '🚨 Critical Findings Summary', 'emoji': True}}]
    fields, overflow = [], []
    for label, value in [('Project', summary['project']), ('Branch', summary['branch']),
                         ('Engagement ID', str(summary['engagement_id'])), ('Report Date', summary['report_date'])]:
        escaped = escape(value)
        styled = f'`{escaped}`' if label == 'Branch' else escaped
        formatted = f'*{label}*\n{styled}'
        if len(formatted) > 2000:
            overflow.extend(_sections(f'{label}\n{value}'))
        elif MARKUP.search(value):
            fields.append(_plain(f'{label}\n{escaped}'))
        else:
            fields.append(_markdown(formatted))
    blocks.append({'type': 'section', 'fields': fields})
    blocks.extend(overflow)
    blocks.extend([{'type': 'divider'}, {'type': 'section', 'fields': [
        _markdown(f'*🔴 Open Critical*\n*{summary["open_count"]}*'),
        _markdown(f'*🆕 New (24h)*\n*{summary["new_count"]}*'),
        _markdown(f'*✅ Fixed (24h)*\n*{summary["fixed_count"]}*')]},
        {'type': 'divider'}, {'type': 'section', 'text': _markdown('*🔎 Critical Findings — Sample*')}])

    def card(sample, shown):
        complete = blocks + sample + [
            {'type': 'context', 'elements': [_markdown(
                f'Showing {shown} of {summary["open_count"]} open critical findings | Source: DefectDojo')]},
            {'type': 'actions', 'elements': [{
                'type': 'button', 'text': {'type': 'plain_text', 'text': 'View All Findings ↗', 'emoji': True},
                'url': summary['url'], 'action_id': 'view_all_findings'}]}]
        return dict(body, text=text, attachments=[{'color': '#DC2626', 'fallback': text, 'blocks': complete}])

    def fits(candidate):
        return (len(candidate['attachments'][0]['blocks']) <= 50
                and len(json.dumps(candidate, ensure_ascii=False, allow_nan=False).encode('utf-8')) <= 65536)

    sample = []
    result = card(sample, 0)
    if not fits(result):
        raise ValueError('payload_too_large')
    for shown, finding in enumerate(summary['findings'], 1):
        candidate_sample = sample + _sample_sections(finding)
        candidate = card(candidate_sample, shown)
        if not fits(candidate):
            break  # Only reduce the oldest prefix; never skip an oversized oldest finding.
        sample, result = candidate_sample, candidate
    return result


def message(event):
    """Build a body, returning plain text for old queue rows and invalid metadata.

    ValueError signals a Slack size violation to the delivery adapter. Its HTTP
    serializer enforces the separate 65536-byte request limit.
    """
    text = escape(event['payload']['text'])
    if len(text) > 39000:
        raise ValueError('payload_too_large')
    body = {'mrkdwn': False, 'parse': 'none', 'link_names': False,
            'unfurl_links': False, 'unfurl_media': False}
    finding, kind = event['payload'].get('finding'), event['kind']
    summary = event['payload'].get('summary')
    if kind == 'digest' and _valid_summary(summary):
        return _summary_message(body, text, summary)
    if not _valid(finding, kind):
        return dict(body, text=text)

    severity = finding['severity']
    icon, color = SEVERITIES[severity]
    status = {'new': 'Open', 'reopened': 'Reopened', 'resolved': 'Fixed', 'suppressed': 'Suppressed'}[kind]
    if kind == 'resolved':
        header, color = '✅ Fixed Security Finding', '#16A34A'
    elif kind == 'suppressed':
        header, color = '⚪ Suppressed Security Finding', '#6B7280'
    else:
        prefix = 'Reopened ' if kind == 'reopened' else ''
        header = f'🚨 {prefix}{severity} Security Finding'
    blocks = [{'type': 'header', 'text': {'type': 'plain_text', 'text': header, 'emoji': True}}]

    title = finding['title']
    match = CVE_TITLE.fullmatch(title)
    if match and not MARKUP.search(title):
        formatted = f'*{match[1]}*\nAffected: `{escape(match[2])}`'
        if len(formatted) <= 3000:
            blocks.append({'type': 'section', 'text': _markdown(formatted)})
        else:
            blocks.extend(_sections(title))
    else:
        blocks.extend(_sections(title))

    fields, overflow = [], []
    values = [('Project', finding['project']), ('Severity', f'{icon} {severity}'),
              ('Branch', finding['branch']), ('Status', status), ('Discovered', finding['discovered'])]
    if kind in ('resolved', 'suppressed'):
        values.append(('Reason', finding['reason'].replace('_', ' ').capitalize()))
    for label, value in values:
        escaped = escape(value)
        styled = f'`{escaped}`' if label == 'Branch' else escaped
        formatted = f'*{label}*\n{styled}'
        if len(formatted) > 2000:
            overflow.extend(_sections(f'{label}\n{value}'))
        elif MARKUP.search(value):
            fields.append(_plain(f'{label}\n{escaped}'))
        else:
            fields.append(_markdown(formatted))
    blocks.append({'type': 'section', 'fields': fields})
    blocks.extend(overflow)
    blocks.append({'type': 'context', 'elements': [_markdown(f'Source: DefectDojo | Event: {kind.upper()}')]})
    blocks.append({'type': 'actions', 'elements': [{
        'type': 'button', 'text': {'type': 'plain_text', 'text': 'View Finding ↗', 'emoji': True},
        'url': finding['url'], 'action_id': 'view_finding'}]})
    if len(blocks) > 50:
        raise ValueError('payload_too_large')
    # A top-level full-text field would visibly duplicate the previous wall of
    # text above the card. Attachment fallback serves notification/plain clients.
    body['attachments'] = [{'color': color, 'fallback': text, 'blocks': blocks}]
    return body
