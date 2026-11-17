"""Slack Block Kit contracts, using only an injected HTTP transport."""
import copy
import json
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'notifier'))
from notifier.delivery import DeliveryError, Sender


def event(kind='new', **finding):
    metadata = dict(id=123, title='CVE-2026-12345 in example-package 1.2.3-r4',
                    project='Example API', branch='main', severity='Critical',
                    reason='open', discovered='2026-11-16',
                    url='https://defectdojo.example.com/finding/123')
    metadata.update(finding)
    return dict(channel='slack', kind=kind,
                payload=dict(title='Original complete title', text='Original full finding text & <details>',
                             finding=metadata))


def digest(**changes):
    summary = dict(project='Example API', branch='main', engagement_id=7,
                   report_date='2026-11-16', open_count=220, new_count=12, fixed_count=3,
                   url='https://defectdojo.example.com/engagement/7',
                   findings=[dict(id=i, title=f'CVE-2026-{12340+i} in example-package 1.2.3-r4',
                                  age_days=11, url=f'https://defectdojo.example.com/finding/{i}')
                             for i in range(1, 6)])
    summary.update(changes)
    return dict(channel='slack', kind='digest', payload=dict(
        text='Critical Findings Summary — Example API | 220 Open | 12 New | 3 Fixed',
        title='Critical summary', summary=summary))


class HTTP:
    def __init__(self, status=200, body=b'ok'):
        self.calls = []
        self.status, self.body = status, body

    def request(self, method, url, **kwargs):
        self.calls.append(kwargs)
        return dict(status=self.status, headers={}, body=self.body)


class SlackCards(unittest.TestCase):
    def send(self, item):
        self.http = HTTP()
        result = Sender({'slack-url': 'https://hooks.slack.com/services/example'}, http=self.http).send(item)
        self.assertEqual(result, {'status': 'delivered'})
        return json.loads(self.http.calls[0]['body'])

    def test_new_card_matches_supplied_layout(self):
        body = self.send(event())
        self.assertNotIn('text', body)
        self.assertEqual(body['attachments'], [{
            'color': '#DC2626', 'fallback': 'Original full finding text &amp; &lt;details&gt;',
            'blocks': [
                {'type': 'header', 'text': {'type': 'plain_text', 'text': '🚨 Critical Security Finding', 'emoji': True}},
                {'type': 'section', 'text': {'type': 'mrkdwn', 'text': '*CVE-2026-12345*\nAffected: `example-package 1.2.3-r4`', 'verbatim': True}},
                {'type': 'section', 'fields': [
                    {'type': 'mrkdwn', 'text': '*Project*\nExample API', 'verbatim': True},
                    {'type': 'mrkdwn', 'text': '*Severity*\n🔴 Critical', 'verbatim': True},
                    {'type': 'mrkdwn', 'text': '*Branch*\n`main`', 'verbatim': True},
                    {'type': 'mrkdwn', 'text': '*Status*\nOpen', 'verbatim': True},
                    {'type': 'mrkdwn', 'text': '*Discovered*\n2026-11-16', 'verbatim': True}]},
                {'type': 'context', 'elements': [{'type': 'mrkdwn', 'text': 'Source: DefectDojo | Event: NEW', 'verbatim': True}]},
                {'type': 'actions', 'elements': [{'type': 'button', 'text': {'type': 'plain_text', 'text': 'View Finding ↗', 'emoji': True},
                                                  'url': 'https://defectdojo.example.com/finding/123', 'action_id': 'view_finding'}]}
            ]}])
        for key in ('mrkdwn', 'link_names', 'unfurl_links', 'unfurl_media'):
            self.assertIs(body[key], False)
        self.assertEqual(body['parse'], 'none')

    def test_conventional_cve_preserves_epoch_and_complete_package_version(self):
        title = 'CVE-2026-56367 libmagickwand-6.q16-6 8:6.9.11.60+dfsg-1.3+deb11u5'
        block = self.send(event(title=title))['attachments'][0]['blocks'][1]
        self.assertEqual(block['text']['text'],
                         '*CVE-2026-56367*\nAffected: `libmagickwand-6.q16-6 8:6.9.11.60+dfsg-1.3+deb11u5`')

    def test_all_suppression_reasons_are_explained_without_fixed_status(self):
        for reason in ('false_positive', 'duplicate', 'out_of_scope', 'risk_accepted', 'inactive', 'severity_changed'):
            with self.subTest(reason=reason):
                attachment = self.send(event('suppressed', reason=reason, severity='Low'))['attachments'][0]
                fields = [f['text'] for b in attachment['blocks'] for f in b.get('fields', [])]
                self.assertIn('*Reason*\n' + reason.replace('_', ' ').capitalize(), fields)
                self.assertIn('*Severity*\n🔵 Low', fields)
                self.assertNotIn('*Status*\nFixed', fields)

    def test_dynamic_markup_and_mentions_are_literal(self):
        item = event(title='CVE-2026-12345 in pkg `break`\n<!here> <@U123> *bold*',
                     project='Example\n<!here> <@U123> *admin* & >', branch='main')
        body = self.send(item)
        blocks = body['attachments'][0]['blocks']
        title = blocks[1]['text']
        self.assertEqual(title['type'], 'plain_text')
        self.assertEqual(title['text'], item['payload']['finding']['title'].replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;'))
        project = next(f for b in blocks for f in b.get('fields', []) if 'Project' in f['text'])
        self.assertEqual(project['type'], 'plain_text')
        self.assertIn('&lt;!here&gt;', project['text'])
        self.assertNotIn('<@U123>', json.dumps(body))

    def test_non_cve_title_is_preserved_without_inventing_a_package(self):
        for title in ('ordinary title', 'CVE-2026-12345 malformed title', 'CVE-2026-12345 in package 1.0\nextra'):
            with self.subTest(title=title):
                blocks = self.send(event(title=title))['attachments'][0]['blocks']
                self.assertEqual(blocks[1]['text']['type'], 'plain_text')
                self.assertEqual(blocks[1]['text']['text'], title)

    def test_long_unicode_title_and_project_are_complete_in_valid_sections(self):
        title = '🔐' * 2999 + '<&>' + 'version-4.5.6' * 100
        project = 'Example' * 500
        blocks = self.send(event(title=title, project=project))['attachments'][0]['blocks']
        sections = [b['text']['text'] for b in blocks if b['type'] == 'section' and 'text' in b]
        escaped = title.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')
        self.assertIn(escaped, ''.join(sections))
        self.assertIn('Project\n' + project, ''.join(sections))
        for block in blocks:
            if block['type'] == 'section' and 'text' in block:
                self.assertLessEqual(len(block['text']['text']), 3000)
            for field in block.get('fields', []):
                self.assertLessEqual(len(field['text']), 2000)
            self.assertLessEqual(len(block.get('fields', [])), 10)

    def test_lifecycle_cards_report_actual_severity_status_and_reason(self):
        cases = [('reopened', 'open', 'Critical', 'Reopened', '#DC2626'),
                 ('resolved', 'fixed', 'Critical', 'Fixed', '#16A34A'),
                 ('suppressed', 'false_positive', 'Critical', 'Suppressed', '#6B7280'),
                 ('suppressed', 'severity_changed', 'High', 'Suppressed', '#6B7280')]
        for kind, reason, severity, status, color in cases:
            with self.subTest(kind=kind, reason=reason):
                body = self.send(event(kind, reason=reason, severity=severity))
                attachment = body['attachments'][0]
                self.assertEqual(attachment['color'], color)
                fields = [f['text'] for b in attachment['blocks'] for f in b.get('fields', [])]
                self.assertIn('*Status*\n' + status, fields)
                self.assertTrue(any(value.endswith(severity) and value.startswith('*Severity*') for value in fields))
                if kind != 'reopened':
                    self.assertIn('*Reason*\n' + reason.replace('_', ' ').capitalize(), fields)
                header = attachment['blocks'][0]['text']['text']
                self.assertIn(status, header)
                if severity == 'High':
                    self.assertNotIn('Critical', header)

    def test_invalid_metadata_and_urls_use_legacy_plain_message(self):
        invalid = [dict(url=url) for url in (
            'javascript:alert(1)', 'https://user:pass@example.com/finding/123',
            'https://example.com/finding/124', 'https://example.com/finding/123?x=1',
            'https://example.com/finding/123#x', 'https://example.com/\\evil/finding/123',
            'https://example.com/finding/123\n', 'https://example.com\u0085/finding/123', 'https://example.com:99999/finding/123',
            'https://example.com:0/finding/123',
            'https://example.com/prefix/finding/123', 'https://' + 'a' * 3000 + '/finding/123')]
        invalid += [dict(id=True), dict(severity='unknown'), dict(discovered='2026-02-31'),
                    dict(reason='unknown'), dict(branch='other'), dict(project=None)]
        for values in invalid:
            with self.subTest(values=values):
                body = self.send(event(**values))
                self.assertNotIn('attachments', body)
                self.assertEqual(body['text'], 'Original full finding text &amp; &lt;details&gt;')

    def test_old_queue_and_digest_retain_plain_text_path(self):
        for kind in ('new', 'digest'):
            item = event(kind)
            if kind == 'new':
                del item['payload']['finding']
            body = self.send(item)
            self.assertNotIn('attachments', body)
            self.assertEqual(body['text'], 'Original full finding text &amp; &lt;details&gt;')

    def test_text_and_http_byte_budgets_reject_before_network(self):
        for text, title in (('&' * 8000, 'normal'), ('a' * 39001, 'normal'),
                            ('🧪' * 17000, 'normal'), ('normal', 'a' * 66000)):
            item = event(title=title)
            item['payload']['text'] = text
            http = HTTP()
            with self.subTest(text_len=len(text), title_len=len(title)):
                with self.assertRaisesRegex(DeliveryError, 'payload_too_large'):
                    Sender({'slack-url': 'https://hooks.slack.com/services/example'}, http=http).send(item)
                self.assertEqual(http.calls, [])

    def test_daily_summary_matches_supplied_layout_and_example(self):
        body = self.send(digest())
        blocks = body['attachments'][0]['blocks']
        self.assertEqual(body['text'],
                         'Critical Findings Summary — Example API | 220 Open | 12 New | 3 Fixed')
        self.assertEqual(body['attachments'][0]['color'], '#DC2626')
        self.assertEqual(blocks[:6], [
            {'type': 'header', 'text': {'type': 'plain_text', 'text': '🚨 Critical Findings Summary', 'emoji': True}},
            {'type': 'section', 'fields': [
                {'type': 'mrkdwn', 'text': '*Project*\nExample API', 'verbatim': True},
                {'type': 'mrkdwn', 'text': '*Branch*\n`main`', 'verbatim': True},
                {'type': 'mrkdwn', 'text': '*Engagement ID*\n7', 'verbatim': True},
                {'type': 'mrkdwn', 'text': '*Report Date*\n2026-11-16', 'verbatim': True}]},
            {'type': 'divider'},
            {'type': 'section', 'fields': [
                {'type': 'mrkdwn', 'text': '*🔴 Open Critical*\n*220*', 'verbatim': True},
                {'type': 'mrkdwn', 'text': '*🆕 New (24h)*\n*12*', 'verbatim': True},
                {'type': 'mrkdwn', 'text': '*✅ Fixed (24h)*\n*3*', 'verbatim': True}]},
            {'type': 'divider'},
            {'type': 'section', 'text': {'type': 'mrkdwn', 'text': '*🔎 Critical Findings — Sample*', 'verbatim': True}}])
        self.assertEqual(len(blocks), 13)
        for i, block in enumerate(blocks[6:11], 1):
            self.assertEqual(block, {'type': 'section', 'text': {
                'type': 'mrkdwn', 'verbatim': True,
                'text': f'🔴 *<https://defectdojo.example.com/finding/{i}|CVE-2026-{12340+i}>*\n`example-package 1.2.3-r4` · 11 days'}})
        self.assertEqual(blocks[-2], {'type': 'context', 'elements': [{
            'type': 'mrkdwn', 'text': 'Showing 5 of 220 open critical findings | Source: DefectDojo', 'verbatim': True}]})
        self.assertEqual(blocks[-1], {'type': 'actions', 'elements': [{
            'type': 'button', 'text': {'type': 'plain_text', 'text': 'View All Findings ↗', 'emoji': True},
            'url': 'https://defectdojo.example.com/engagement/7', 'action_id': 'view_all_findings'}]})
        example = json.loads((Path(__file__).resolve().parents[1] / 'examples/notifications/slack-summary.example.json').read_text())
        self.assertEqual(body, example)
        for key in ('mrkdwn', 'link_names', 'unfurl_links', 'unfurl_media'):
            self.assertIs(body[key], False)
        self.assertEqual(body['parse'], 'none')

    def test_summary_preserves_complete_versions_and_literal_hostile_titles(self):
        item = digest(project='Project *admin* <!here> <@U123> & >')
        rows = item['payload']['summary']['findings']
        rows[0]['title'] = 'CVE-2026-56367 libmagickwand-6.q16-6 8:6.9.11.60+dfsg-1.3+deb11u5'
        rows[1]['title'] = 'Bad `version` <!here> <@U123> *bold* <https://scanner.example.com|click> & >'
        body = self.send(item)
        blocks = body['attachments'][0]['blocks']
        self.assertIn('`libmagickwand-6.q16-6 8:6.9.11.60+dfsg-1.3+deb11u5` · 11 days', blocks[6]['text']['text'])
        literal = next(b['text'] for b in blocks if b.get('text', {}).get('text', '').startswith('Bad'))
        self.assertEqual(literal, {'type': 'plain_text', 'text': rows[1]['title'].replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;'), 'emoji': False})
        project = blocks[1]['fields'][0]
        self.assertEqual(project['type'], 'plain_text')
        self.assertIn('&lt;!here&gt;', project['text'])
        serialized = json.dumps(body)
        self.assertNotIn('<@U123>', serialized)
        self.assertNotIn('<https://scanner.example.com|click>', serialized)
        self.assertIn('<https://defectdojo.example.com/finding/2|', serialized)

    def test_summary_invalid_metadata_and_noncanonical_urls_use_legacy_text(self):
        cases = [dict(project=None), dict(branch='other'), dict(engagement_id=True),
                 dict(engagement_id=0), dict(report_date='2026-02-31'), dict(report_date='20261116'),
                 dict(open_count=True), dict(open_count=-1), dict(open_count=4),
                 dict(new_count=1.5), dict(fixed_count='3'), dict(findings={}),
                 dict(findings=[None]), dict(findings=digest()['payload']['summary']['findings'] * 2)]
        cases += [dict(url=url) for url in (
            'javascript:alert(1)', 'https://user:pass@example.com/engagement/7',
            'https://defectdojo.example.com/engagement/8', 'https://defectdojo.example.com/engagement/7?',
            'https://defectdojo.example.com/engagement/7#', 'https://defectdojo.example.com:0/engagement/7',
            'https://defectdojo.example.com:99999/engagement/7', 'https://defectdojo.example.com/engagement/7\n',
            'https://dojo.example.com|evil/engagement/7', 'https://dojo.example.com/engagement/%37',
            'https://dojo.example.com/prefix/engagement/7')]
        for changes in cases:
            with self.subTest(changes=changes):
                item = digest(**changes)
                body = self.send(item)
                self.assertNotIn('attachments', body)
                self.assertEqual(body['text'], item['payload']['text'])
        for change in (dict(id=True), dict(id=0), dict(title=None), dict(age_days=-1), dict(age_days=True),
                       dict(url='https://scanner.example.com/finding/1'),
                       dict(url='https://defectdojo.example.com/finding/2'),
                       dict(url='https://defectdojo.example.com/finding/1?x=1')):
            with self.subTest(change=change):
                item = digest()
                item['payload']['summary']['findings'][0].update(change)
                self.assertNotIn('attachments', self.send(item))
        item = digest()
        item['payload']['summary']['findings'][1] = copy.deepcopy(item['payload']['summary']['findings'][0])
        self.assertNotIn('attachments', self.send(item))

    def test_summary_unicode_sample_uses_oldest_prefix_with_complete_included_titles(self):
        item = digest()
        rows = item['payload']['summary']['findings']
        for row in rows:
            row['title'] = f"Finding {row['id']} " + '🔐' * 5500 + ' complete-version-8:6.9.11.60+deb11u5'
        body = self.send(item)
        blocks = body['attachments'][0]['blocks']
        context = blocks[-2]['elements'][0]['text']
        shown = int(context.split()[1])
        self.assertGreater(shown, 0)
        self.assertLess(shown, 5)
        literal = ''.join(b['text']['text'] for b in blocks if b.get('text', {}).get('type') == 'plain_text')
        for row in rows[:shown]:
            self.assertIn(row['title'], literal)
        for row in rows[shown:]:
            self.assertNotIn(f"Finding {row['id']} ", literal)
        self.assertLessEqual(len(blocks), 50)
        self.assertLessEqual(len(self.http.calls[0]['body']), 65536)
        self.assertEqual(context, f'Showing {shown} of 220 open critical findings | Source: DefectDojo')
        for block in blocks:
            if block['type'] == 'section' and 'text' in block:
                self.assertLessEqual(len(block['text']['text']), 3000)
            for field in block.get('fields', []):
                self.assertLessEqual(len(field['text']), 2000)

    def test_summary_oversized_first_finding_never_skips_it_for_newer_findings(self):
        item = digest()
        item['payload']['summary']['findings'][0]['title'] = '🧪' * 70000
        body = self.send(item)
        self.assertEqual(body['attachments'][0]['blocks'][-2]['elements'][0]['text'],
                         'Showing 0 of 220 open critical findings | Source: DefectDojo')
        self.assertNotIn('/finding/', json.dumps(body))

    def test_card_keeps_existing_provider_confirmation(self):
        for item in (event(), digest()):
            for status, reply in ((200, b'no'), (202, b'ok')):
                with self.subTest(kind=item['kind'], status=status), self.assertRaisesRegex(DeliveryError, 'provider_rejected'):
                    Sender({'slack-url': 'https://hooks.slack.com/services/example'}, http=HTTP(status, reply)).send(item)


if __name__ == '__main__':
    unittest.main()
