"""Optional Opsgenie title context must not change delivery identity or other channels."""
import copy
from contextlib import redirect_stdout
import io
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

from test_notifications_delivery import FakeHTTP, SECRETS, event, response

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'notifier'))
from notifier import config
from notifier.__main__ import main
from notifier.delivery import Sender, DeliveryError


def policy():
    return dict(namespace='a' * 64, api_url='https://dojo.example.com', engagement_ids=[1],
                all_engagements=False, time_zone='UTC',
                mysql=dict(host='mysql.example.com', port=3306, database='notifier', tls=True),
                opsgenie_region='us', priority='P2')


UNICODE_PREFIX_CASES = (
    ('zwj_at_limit', 'x' * 77 + '👩‍💻', True),
    ('zwj_over_limit', 'x' * 78 + '👩‍💻', False),
    ('flag_at_limit', 'x' * 78 + '🇦🇲', True),
    ('flag_over_limit', 'x' * 79 + '🇦🇲', False),
    ('variation_at_limit', 'x' * 78 + '✈️', True),
    ('variation_over_limit', 'x' * 79 + '✈️', False),
    ('combining_at_limit', 'x' * 78 + 'x́', True),
    ('combining_over_limit', 'x' * 79 + 'x́', False),
    ('cyrillic_at_limit', 'А' * 80, True),
    ('cyrillic_over_limit', 'А' * 81, False),
)


class TitlePrefixTests(unittest.TestCase):
    def test_opsgenie_finding_reopened_and_digest_prefix_only_message(self):
        for kind in ('new', 'reopened', 'digest'):
            with self.subTest(kind=kind):
                item = event(kind=kind)
                before = copy.deepcopy(item)
                http = FakeHTTP(response(202, {'requestId': 'receipt-1'}))
                Sender(SECRETS, http=http, title_prefix='Example Security:').send(item)
                body = json.loads(http.calls[0][2]['body'])
                self.assertEqual(body['message'], 'Example Security: A vulnerability')
                self.assertEqual(body['description'], item['payload']['text'])
                self.assertEqual(body['alias'], item['payload']['alias'])
                self.assertEqual(body['tags'], ['defectdojo', 'defectdojo-summary' if kind == 'digest' else 'defectdojo-finding'])
                self.assertEqual(body['priority'], 'P5' if kind == 'digest' else 'P2')
                self.assertEqual(item, before)

    def test_empty_default_preserves_title_and_combined_title_is_bounded(self):
        for prefix in ('', 'Example Security:', 'x' * 80):
            with self.subTest(prefix=prefix):
                item = event()
                item['payload']['title'] = 'Finding ' * 100
                http = FakeHTTP(response(202, {'requestId': 'receipt-1'}))
                Sender(SECRETS, http=http, title_prefix=prefix).send(item)
                body = json.loads(http.calls[0][2]['body'])
                expected = ((prefix + ' ') if prefix else '') + item['payload']['title']
                self.assertEqual(body['message'], expected[:130])
                self.assertEqual(len(body['message']), 130)

    def test_prefix_does_not_change_slack_or_teams_requests(self):
        for channel in ('slack', 'teams'):
            requests = []
            for prefix in ('', 'Example Security:'):
                http = FakeHTTP(response(200, body=b'ok'))
                Sender(SECRETS, http=http, title_prefix=prefix).send(event(channel))
                requests.append(http.calls)
            self.assertEqual(requests[0], requests[1])

    def test_invalid_prefix_is_rejected_before_requests(self):
        for value in (None, True, 1, [], 'x' * 81, ' lead', 'tail ', 'bad\nvalue', 'bad\x00value', 'bad\x7fvalue'):
            with self.subTest(value=value), self.assertRaisesRegex(DeliveryError, 'invalid_title_prefix'):
                Sender(SECRETS, title_prefix=value)

    def test_policy_accepts_optional_prefix_and_rejects_invalid_values(self):
        self.assertEqual(config.validate(policy()), policy())
        for value in ('', 'Example Security:'):
            actual = config.validate(dict(policy(), opsgenie_title_prefix=value))
            self.assertEqual(actual['opsgenie_title_prefix'], value)
        for value in (None, True, 'x' * 81, ' lead', 'tail ', 'bad\nvalue', 'bad\x00value', 'bad\x7fvalue'):
            with self.subTest(value=value), self.assertRaisesRegex(config.ConfigError, 'invalid_opsgenie_title_prefix'):
                config.validate(dict(policy(), opsgenie_title_prefix=value))

    def test_unicode_codepoint_boundary_matches_config_and_sender(self):
        for name, prefix, accepted in UNICODE_PREFIX_CASES:
            with self.subTest(case=name):
                self.assertEqual(len(prefix), 80 if accepted else 81)
                configured = dict(policy(), opsgenie_title_prefix=prefix)
                if accepted:
                    self.assertEqual(config.validate(configured)['opsgenie_title_prefix'], prefix)
                    self.assertEqual(Sender({}, title_prefix=prefix).title_prefix, prefix)
                else:
                    with self.assertRaisesRegex(config.ConfigError, 'invalid_opsgenie_title_prefix'):
                        config.validate(configured)
                    with self.assertRaisesRegex(DeliveryError, 'invalid_title_prefix'):
                        Sender({}, title_prefix=prefix)

    def test_cli_passes_configured_prefix_to_sender(self):
        with tempfile.TemporaryDirectory() as directory:
            for name in ('api-token', 'mysql-user', 'mysql-password', 'opsgenie-key'):
                Path(directory, name).write_text('example-value')
            with patch.dict(os.environ, SECRET_DIR=directory), \
                    patch('notifier.config.load', return_value=dict(policy(), opsgenie_title_prefix='Example Security:')), \
                    patch('notifier.__main__.MySQLStore.connect'), \
                    patch('notifier.__main__.API'), patch('notifier.__main__.Source'), \
                    patch('notifier.__main__.Engine') as engine, \
                    patch('notifier.delivery.Sender') as sender, redirect_stdout(io.StringIO()):
                engine.return_value.run.return_value = {}
                self.assertEqual(main(['poll']), 0)
            self.assertEqual(sender.call_args.kwargs['title_prefix'], 'Example Security:')


class TitlePrefixTerraformTests(unittest.TestCase):
    def test_optional_prefix_survives_helm_policy_and_invalid_values_fail(self):
        good = dict(enabled=True, api_url='https://dojo.example.com', all_engagements=True,
                    channels_secret=dict(name='example-channels'))
        fixture = 'mock_provider "helm" {}\n'
        for name, prefix in (('legacy', None), ('configured', 'Example Security:')):
            value = dict(good)
            if prefix is not None:
                value['opsgenie_title_prefix'] = prefix
            expected = ('!contains(keys(jsondecode(helm_release.notifications[0].values[0]).policy), "opsgenie_title_prefix")'
                        if prefix is None else 'jsondecode(helm_release.notifications[0].values[0]).policy.opsgenie_title_prefix == "Example Security:"')
            fixture += 'run "' + name + '" {\n command = plan\n variables {\n notifications = ' + json.dumps(value) + '\n }\n'
            fixture += ' assert {\n condition = ' + expected + '\n error_message = "Optional prefix transport changed."\n }\n'
            fixture += ' assert {\n condition = jsondecode(helm_release.notifications[0].values[0]).policy.namespace == sha256(jsonencode([var.namespace, var.name, "https://dojo.example.com"]))\n error_message = "Title prefix must not reset database history."\n }\n}\n'
        for index, prefix in enumerate(('x' * 81, ' lead', 'tail ', 'bad\nvalue', 'bad\x7fvalue')):
            value = dict(good, opsgenie_title_prefix=prefix)
            fixture += 'run "invalid_' + str(index) + '" {\n command = plan\n variables {\n notifications = ' + json.dumps(value) + '\n }\n expect_failures = [var.notifications]\n}\n'
        for name, prefix, accepted in UNICODE_PREFIX_CASES:
            value = dict(good, opsgenie_title_prefix=prefix)
            fixture += 'run "unicode_' + name + '" {\n command = plan\n variables {\n notifications = ' + json.dumps(value, ensure_ascii=False) + '\n }\n'
            if accepted:
                fixture += ' assert {\n condition = jsondecode(helm_release.notifications[0].values[0]).policy.opsgenie_title_prefix == ' + json.dumps(prefix, ensure_ascii=False) + '\n error_message = "Accepted Unicode prefix must reach Python unchanged."\n }\n'
            else:
                fixture += ' expect_failures = [var.notifications]\n'
            fixture += '}\n'
        with tempfile.TemporaryDirectory() as directory:
            directory = Path(directory)
            for path in ROOT.glob('*.tf'):
                shutil.copy(path, directory / path.name)
            shutil.copy(ROOT / '.terraform.lock.hcl', directory / '.terraform.lock.hcl')
            for name in ('.terraform', 'charts', 'notifier'):
                (directory / name).symlink_to(ROOT / name, target_is_directory=True)
            (directory / 'tests').mkdir()
            (directory / 'tests/prefix.tftest.hcl').write_text(fixture)
            result = subprocess.run(['terraform', '-chdir=' + str(directory), 'test', '-no-color'], capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
