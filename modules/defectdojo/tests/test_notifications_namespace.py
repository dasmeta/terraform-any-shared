"""Canonical API origin must preserve the notification ledger's identity."""
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class NotificationNamespaceTests(unittest.TestCase):
    def test_equivalent_origins_share_namespace_and_other_origins_stay_distinct(self):
        if not shutil.which('terraform') or not (ROOT / '.terraform/providers').exists():
            self.skipTest('Initialized Terraform provider required for offline plans')
        fixture = 'mock_provider "helm" {}\n'
        cases = [
            ('https_bare', 'https://dojo.example.com', 'https://dojo.example.com'),
            ('https_default', 'https://dojo.example.com:443', 'https://dojo.example.com'),
            ('https_case_slash', 'HTTPS://DOJO.example.com:443/', 'https://dojo.example.com'),
            ('https_padded_default', 'https://dojo.example.com:00443/', 'https://dojo.example.com'),
            ('http_bare', 'http://dojo.example.com', 'http://dojo.example.com'),
            ('http_default', 'http://dojo.example.com:80/', 'http://dojo.example.com'),
            ('http_padded_default', 'http://dojo.example.com:00080', 'http://dojo.example.com'),
            ('https_nondefault', 'https://dojo.example.com:8443', 'https://dojo.example.com:8443'),
            ('http_nondefault', 'http://dojo.example.com:8080/', 'http://dojo.example.com:8080'),
            ('other_host', 'https://other.example.com', 'https://other.example.com'),
        ]
        expected = {}
        for label, url, origin in cases:
            # Preserve the deployed bare-origin formula and distinguish real
            # endpoint changes; only equivalent URL syntax is canonicalized.
            state = hashlib.sha256(json.dumps(['example-security', 'example', origin],
                                             separators=(',', ':')).encode()).hexdigest()
            expected[label] = state
            config = dict(api_url=url, all_engagements=True,
                          channels_secret={'name': 'example-channels'},
                          api_token_secret={'name': 'example-api'})
            fixture += ('run "' + label + '" {\n command = plan\n variables {\n'
                        ' name = "example"\n namespace = "example-security"\n'
                        ' notifications = ' + json.dumps(config) + '\n }\n assert {\n'
                        ' condition = output.notifications.state_namespace == "' + state + '"'
                        ' && jsondecode(helm_release.notifications[0].values[0]).policy.namespace == "' + state + '"\n'
                        ' error_message = "Equivalent API origins must preserve state and remote alert identities."\n }\n}\n')
        self.assertEqual(expected['https_bare'], expected['https_default'])
        self.assertEqual(expected['http_bare'], expected['http_default'])
        self.assertEqual(len(set(expected.values())), 5)
        with tempfile.TemporaryDirectory() as directory:
            directory = Path(directory)
            for path in ROOT.glob('*.tf'):
                shutil.copy(path, directory / path.name)
            shutil.copy(ROOT / '.terraform.lock.hcl', directory / '.terraform.lock.hcl')
            for name in ('.terraform', 'charts', 'notifier'):
                (directory / name).symlink_to(ROOT / name, target_is_directory=True)
            (directory / 'tests').mkdir()
            (directory / 'tests/namespace.tftest.hcl').write_text(fixture)
            result = subprocess.run(['terraform', '-chdir=' + str(directory), 'test', '-no-color'],
                                    capture_output=True, text=True,
                                    env=dict(os.environ, TF_IN_AUTOMATION='1'))
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
