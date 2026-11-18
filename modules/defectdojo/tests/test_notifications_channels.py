"""Direct channel source selection and sensitive Helm transport, entirely offline."""

import base64
import copy
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
CHANNELS = {
    "slack_webhook_url": "https://hooks.example.com/slack?value=a,b={c}&signature=example\\token",
    "teams_webhook_url": "https://workflows.example.com/teams?signature=example==",
    "opsgenie_api_key": "example-individual-key",
}


class NotificationChannelsTerraformTests(unittest.TestCase):
    def test_direct_explicit_disabled_invalid_and_sensitive_channels(self):
        if not shutil.which("terraform") or not (ROOT / ".terraform/providers").exists():
            self.skipTest("Terraform with initialized Helm provider required for offline plan checks")
        version = json.loads(subprocess.check_output(["terraform", "version", "-json"], text=True))["terraform_version"]
        if tuple(int(part) for part in version.split(".")[:2]) < (1, 8):
            self.skipTest("Terraform >=1.8 required for offline sensitivity assertions; module remains >=1.3")
        good = {"enabled": True, "api_url": "https://defectdojo.example.com", "all_engagements": True, "channels": CHANNELS}
        fixture = 'mock_provider "helm" {}\n'

        def run(name, config, checks=(), invalid=False, sensitive=False):
            nonlocal fixture
            expression = json.dumps(config)
            if sensitive:
                channels = json.dumps(config["channels"])
                expression = expression.replace(channels, "sensitive(" + channels + ")")
            fixture += 'run "' + name + '" {\n command = plan\n variables {\n notifications = ' + expression + '\n }\n'
            for check in checks:
                fixture += ' assert {\n condition = ' + check + '\n error_message = "Direct channel source selection, sensitive transport or ownership changed."\n }\n'
            if invalid:
                fixture += ' expect_failures = [var.notifications]\n'
            fixture += '}\n'

        transport = 'helm_release.notifications[0].set_sensitive'
        values = 'jsondecode(helm_release.notifications[0].values[0])'
        direct_checks = [
            'length(helm_release.notifications) == 1 && length(helm_release.notifications_mysql) == 1 && length(helm_release.notifications_mysql_bootstrap) == 1',
            values + '.createChannelsSecret && ' + values + '.channelsSecret.name == "defectdojo-notifications-channels"',
            'toset(values(' + values + '.channelsSecret)) == toset(["defectdojo-notifications-channels", "slack-url", "teams-url", "opsgenie-key"])',
            'toset(keys(var.notifications.channels)) == toset(["slack_webhook_url", "teams_webhook_url", "opsgenie_api_key"]) && toset(keys(var.notifications.channels_secret)) == toset(["name", "slack_key", "teams_key", "opsgenie_key"])',
            '!contains(keys(' + values + '), "channelsData") && !contains(keys(' + values + '.policy), "channels")',
            '!contains(keys(var.notifications), "dry_run") && !contains(keys(output.notifications), "dry_run")',
            'toset(keys(' + values + '.policy)) == toset(["namespace", "api_url", "engagement_ids", "all_engagements", "time_zone", "mysql", "opsgenie_region", "priority"])',
            '!issensitive(helm_release.notifications[0].values) && !issensitive(output.notifications)',
            'length(' + transport + ') == 3 && alltrue([for setting in ' + transport + ' : setting.type == "string"])',
        ]
        mapping = {"slack-url": "slack_webhook_url", "teams-url": "teams_webhook_url", "opsgenie-key": "opsgenie_api_key"}
        def transport_checks(channels):
            checks = list(direct_checks)
            for key, field in mapping.items():
                credential = channels.get(field, "")
                encoded = base64.b64encode(credential.encode()).decode()
                checks.append('one([for setting in ' + transport + ' : setting.value if setting.name == "channelsData.' + key + '"]) == "' + encoded + '"')
                if credential:
                    checks.append('!strcontains(helm_release.notifications[0].values[0], ' + json.dumps(credential) + ') && !strcontains(jsonencode(output.notifications), ' + json.dumps(credential) + ')')
            return checks

        for label, fields in [
            ("slack_only", ["slack_webhook_url"]),
            ("teams_only", ["teams_webhook_url"]),
            ("opsgenie_only", ["opsgenie_api_key"]),
            ("slack_teams", ["slack_webhook_url", "teams_webhook_url"]),
            ("slack_opsgenie", ["slack_webhook_url", "opsgenie_api_key"]),
            ("teams_opsgenie", ["teams_webhook_url", "opsgenie_api_key"]),
        ]:
            channels = {field: CHANNELS[field] for field in fields}
            run(label, dict(good, channels=channels), transport_checks(channels), sensitive=True)
        run("direct_channels", good, transport_checks(CHANNELS))
        run("sensitive_channels", good, transport_checks(CHANNELS), sensitive=True)
        run("retained_database_still_owns_channels", dict(good, retain_state=True), transport_checks(CHANNELS))
        run("disabled_with_sensitive_channels", dict(good, enabled=False), [
            'length(helm_release.notifications) == 0 && length(helm_release.notifications_mysql) == 0 && length(helm_release.notifications_mysql_bootstrap) == 0 && length(helm_release.notifications_api_bootstrap) == 0 && output.notifications == null',
        ], sensitive=True)
        implicit = dict(good)
        implicit.pop("enabled")
        run("shared_channels_auto_enable", implicit, transport_checks(CHANNELS), sensitive=True)
        for label, field in (("slack", "slack_webhook_url"), ("teams", "teams_webhook_url"), ("opsgenie", "opsgenie_api_key")):
            channels = {field: CHANNELS[field]}
            run("auto_" + label, dict(implicit, channels=channels), transport_checks(channels), sensitive=True)
        run("null_enabled_auto", dict(implicit, enabled=None), transport_checks(CHANNELS), sensitive=True)
        off = 'length(helm_release.notifications) == 0 && length(helm_release.notifications_mysql) == 0 && length(helm_release.notifications_mysql_bootstrap) == 0 && length(helm_release.notifications_api_bootstrap) == 0 && output.notifications == null'
        for label, config in (("empty", {}), ("null_channels", {"channels": None}),
                              ("blank", {"channels": {"slack_webhook_url": " \t "}}),
                              ("api_secret_only", {"api_token_secret": {"name": "example-api"}})):
            run("auto_off_" + label, config, [off], sensitive=(label == "blank"))
        explicit = copy.deepcopy(good)
        explicit.pop("channels")
        explicit["channels_secret"] = {"name": "example-existing-channels", "slack_key": "custom-slack"}
        run("explicit_channels", explicit, [
            '!' + values + '.createChannelsSecret && ' + values + '.channelsSecret.name == "example-existing-channels" && ' + values + '.channelsSecret.slackKey == "custom-slack"',
            'length(' + transport + ') == 0',
        ])
        auto_secret = dict(explicit)
        auto_secret.pop("enabled")
        run("existing_secret_auto_enables", auto_secret, [
            'length(helm_release.notifications) == 1 && !' + values + '.createChannelsSecret && length(' + transport + ') == 0',
        ])
        for label, config in (("url", dict(implicit, api_url="not-an-origin")),
                              ("selector", dict(implicit, all_engagements=False)),
                              ("mixed_sources", dict(implicit, channels_secret={"name": "example-channels"})),
                              ("external_db", dict(implicit, mysql={"create": False, "host": "", "credentials_secret": {"name": "example-db"}}))):
            run("invalid_auto_" + label, config, invalid=True, sensitive=True)
        invalids = {"missing_source": dict(explicit, channels_secret={}), "both_sources": dict(good, channels_secret={"name": "example-existing-channels"})}
        for field in CHANNELS:
            whitespace = copy.deepcopy(good)
            whitespace["channels"][field] = " \n\t "
            invalids["blank_" + field] = whitespace
            partial_explicit = copy.deepcopy(explicit)
            partial_explicit["channels"] = {field: CHANNELS[field]}
            invalids["explicit_and_" + field] = partial_explicit
        invalids["custom_inline_keys"] = dict(good, channels_secret={"slack_key": "custom-slack"})
        invalids["invalid_secret_name"] = dict(explicit, channels_secret={"name": "BAD/name"})
        for name, config in invalids.items():
            run(name, config, invalid=True)

        with tempfile.TemporaryDirectory() as directory:
            directory = Path(directory)
            for path in ROOT.glob("*.tf"):
                shutil.copy(path, directory / path.name)
            shutil.copy(ROOT / ".terraform.lock.hcl", directory / ".terraform.lock.hcl")
            for name in [".terraform", "charts", "notifier"]:
                (directory / name).symlink_to(ROOT / name, target_is_directory=True)
            tests = directory / "tests"
            tests.mkdir()
            (tests / "channels.tftest.hcl").write_text(fixture)
            result = subprocess.run(["terraform", "-chdir=" + str(directory), "test", "-no-color"], capture_output=True, text=True, env=dict(os.environ, TF_IN_AUTOMATION="1"))
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)


if __name__ == "__main__":
    unittest.main()
