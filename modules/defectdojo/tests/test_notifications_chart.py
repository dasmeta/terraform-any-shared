"""Offline Helm rendering and Terraform plan checks; no cluster or provider delivery."""

import copy
import base64
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
HELM = os.environ.get("HELM_BIN", "helm")


class NotificationChartTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.directory = Path(self.temp.name)
        self.values = {
            "enabled": True,
            "managedMysql": False,
            "sourceFiles": {path.name: path.read_text() for path in (ROOT / "notifier/notifier").glob("*.py")},
            "wheelFiles": {path.name: base64.b64encode(path.read_bytes()).decode() for path in (ROOT / "notifier/vendor").glob("*.whl")},
            "apiTokenSecret": {"name": "example-api", "key": "token"},
            "mysqlCredentialsSecret": {"name": "example-db", "usernameKey": "user", "passwordKey": "password"},
            "channelsSecret": {"name": "example-channels", "slackKey": "slack", "teamsKey": "teams", "opsgenieKey": "alerts"},
            "policy": {
                "namespace": "a" * 64,
                "api_url": "https://defectdojo.example.com",
                "engagement_ids": [7],
                "all_engagements": False,
                "time_zone": "UTC",
                "mysql": {"host": "mysql.example.com", "port": 3306, "database": "notifications", "tls": True},
                "opsgenie_region": "us",
                "priority": "P2",
            },
        }

    def render(self, values=None, version="1.27.0", success=True, release="example-notifications"):
        values_file = self.directory / "values.json"
        # Match Terraform's UTF-8 JSON values. Helm's YAML reader rejects the
        # surrogate-pair escapes emitted by json.dumps' ensure_ascii default.
        values_file.write_text(json.dumps(self.values if values is None else values,
                                         ensure_ascii=False), encoding='utf-8')
        result = subprocess.run(
            [HELM, "template", release, str(ROOT / "charts/notifications"), "--namespace", "example", "--kube-version", version, "-f", str(values_file)],
            capture_output=True, text=True,
            env=dict(os.environ, HELM_PLUGINS=str(self.directory / "plugins")),
        )
        if not success:
            self.assertNotEqual(result.returncode, 0)
            return []
        self.assertEqual(result.returncode, 0, result.stderr)
        manifest = self.directory / "rendered.yaml"
        manifest.write_text(result.stdout)
        output = subprocess.check_output(
            ["ruby", "-ryaml", "-rjson", "-e", "puts JSON.generate(YAML.load_stream(File.read(ARGV[0])).compact)", str(manifest)], text=True,
        )
        return json.loads(output)

    def test_disabled_chart_renders_no_resources(self):
        self.assertEqual(self.render({}), [])

    def test_direct_channels_secret_has_exact_data_and_worker_references(self):
        credentials = {
            "slack-url": "https://hooks.example.com/slack?value=a,b={c}&signature=example\\token",
            "teams-url": "https://workflows.example.com/teams?signature=example==",
            "opsgenie-key": "example-individual-key",
        }
        values = copy.deepcopy(self.values)
        values.update(createChannelsSecret=True, retainState=True)
        values["channelsSecret"] = {
            "name": "example-notifications-channels", "slackKey": "slack-url", "teamsKey": "teams-url",
            "opsgenieKey": "opsgenie-key",
        }
        values["channelsData"] = {key: base64.b64encode(value.encode()).decode() for key, value in credentials.items()}
        documents = self.render(values)
        secrets = [document for document in documents if document["kind"] == "Secret"]
        self.assertEqual(len(secrets), 1)
        secret = secrets[0]
        self.assertEqual(secret["metadata"]["name"], "example-notifications-channels")
        self.assertEqual(secret["type"], "Opaque")
        self.assertEqual(secret["data"], values["channelsData"])
        self.assertEqual({key: base64.b64decode(value).decode() for key, value in secret["data"].items()}, credentials)
        self.assertNotIn("helm.sh/resource-policy", secret["metadata"].get("annotations", {}))
        self.assertNotIn("helm.sh/hook", secret["metadata"].get("annotations", {}))
        for document in documents:
            if document["kind"] == "CronJob":
                volumes = document["spec"]["jobTemplate"]["spec"]["template"]["spec"]["volumes"]
                source = next(source["secret"] for volume in volumes if "projected" in volume for source in volume["projected"]["sources"] if source["secret"]["name"] == secret["metadata"]["name"])
                self.assertEqual({item["path"]: item["key"] for item in source["items"]}, {key: key for key in credentials})
            if document["kind"] != "Secret":
                serialized = json.dumps(document)
                for key, value in credentials.items():
                    self.assertNotIn(value, serialized)
                    self.assertNotIn(values["channelsData"][key], serialized)

    def test_direct_channels_disabled_or_explicit_mode_creates_no_secret(self):
        for values in [dict(self.values, createChannelsSecret=False), {"enabled": False, "createChannelsSecret": True}]:
            self.assertFalse(any(document["kind"] == "Secret" for document in self.render(values)))

    def test_direct_channels_renders_only_selected_destinations(self):
        for keys in [
            ["slack-url"], ["teams-url"], ["opsgenie-key"],
            ["slack-url", "teams-url"], ["slack-url", "opsgenie-key"],
            ["teams-url", "opsgenie-key"],
        ]:
            values = copy.deepcopy(self.values)
            values["createChannelsSecret"] = True
            values["channelsSecret"] = {"name": "example-channels", "slackKey": "slack-url", "teamsKey": "teams-url", "opsgenieKey": "opsgenie-key"}
            values["channelsData"] = {key: base64.b64encode(("example-" + key).encode()).decode() for key in keys}
            with self.subTest(keys=keys):
                documents = self.render(values)
                secret = next(document for document in documents if document["kind"] == "Secret")
                self.assertEqual(secret["data"], values["channelsData"])

    def test_channels_projection_is_optional_while_api_and_mysql_are_required(self):
        for document in self.render():
            if document["kind"] != "CronJob":
                continue
            volumes = document["spec"]["jobTemplate"]["spec"]["template"]["spec"]["volumes"]
            sources = [source["secret"] for volume in volumes if "projected" in volume for source in volume["projected"]["sources"]]
            for source in sources:
                self.assertEqual(source.get("optional", False), source["name"] == "example-channels")

    def test_direct_channels_requires_destination_and_default_keys(self):
        values = copy.deepcopy(self.values)
        values["createChannelsSecret"] = True
        values["channelsSecret"] = {"name": "example-channels", "slackKey": "slack-url", "teamsKey": "teams-url", "opsgenieKey": "opsgenie-key"}
        values["channelsData"] = {key: base64.b64encode(("example-" + key).encode()).decode() for key in ["slack-url", "teams-url", "opsgenie-key"]}
        invalid_data = [{}]
        for key in values["channelsData"]:
            invalid_data.append(dict(values["channelsData"], **{key: base64.b64encode(b" \n\t ").decode()}))
        for data in invalid_data:
            invalid = copy.deepcopy(values)
            invalid["channelsData"] = data
            with self.subTest(keys=list(data)):
                self.render(invalid, success=False)
        values["channelsSecret"]["slackKey"] = "custom-slack"
        self.render(values, success=False)

    def test_exactly_two_scheduled_jobs_and_nonsecret_policy(self):
        docs = self.render()
        self.assertEqual(sorted(d["kind"] for d in docs), ["ConfigMap", "ConfigMap", "ConfigMap", "CronJob", "CronJob"])
        config = next(d for d in docs if "policy.json" in d.get("data", {}))
        self.assertEqual(set(config["data"]), {"policy.json"})
        self.assertEqual(json.loads(config["data"]["policy.json"]), self.values["policy"])
        self.assertEqual(set(self.values["policy"]), {"namespace", "api_url", "engagement_ids", "all_engagements", "time_zone", "mysql", "opsgenie_region", "priority"})
        jobs = {d["metadata"]["name"].rsplit("-", 1)[1]: d for d in docs if d["kind"] == "CronJob"}
        self.assertEqual(set(jobs), {"poll", "digest"})
        for kind, schedule in [("poll", "0 * * * *"), ("digest", "30 13 * * *")]:
            cron = jobs[kind]["spec"]
            self.assertEqual(cron["schedule"], schedule)
            self.assertEqual(cron["timeZone"], "UTC")
            self.assertEqual(cron["concurrencyPolicy"], "Forbid")
            job = cron["jobTemplate"]["spec"]
            self.assertEqual(job["backoffLimit"], 10)
            self.assertEqual(job["activeDeadlineSeconds"], 3600)
            pod = job["template"]["spec"]
            self.assertFalse(pod["automountServiceAccountToken"])
            self.assertTrue(pod["securityContext"]["runAsNonRoot"])
            self.assertEqual(pod["securityContext"]["seccompProfile"]["type"], "RuntimeDefault")
            container = pod["containers"][0]
            self.assertTrue(container["image"].startswith("python:3.12-slim@sha256:"))
            self.assertEqual(container["command"], ["python", "-m", "notifier", kind])
            self.assertTrue(container["securityContext"]["readOnlyRootFilesystem"])
            self.assertFalse(container["securityContext"]["allowPrivilegeEscalation"])
            self.assertEqual(container["securityContext"]["capabilities"]["drop"], ["ALL"])
            self.assertEqual(set(container["resources"]), {"requests", "limits"})
            self.assertTrue(all(m["readOnly"] for m in container["volumeMounts"]))
            mounts = {m["name"]: m["mountPath"] for m in container["volumeMounts"]}
            self.assertEqual(mounts["config"], "/config")
            self.assertEqual(mounts["credentials"], "/var/run/secrets/notifications")
            self.assertIn("/app", mounts.values())
            self.assertIn("/deps", mounts.values())
            pythonpath = next(e["value"] for e in container["env"] if e["name"] == "PYTHONPATH")
            self.assertEqual(pythonpath.split(":"), ["/app"] + ["/deps/" + name for name in sorted(self.values["wheelFiles"])])
            self.assertIn({"name": "POLICY_FILE", "value": "/config/policy.json"}, container["env"])
            self.assertIn({"name": "SECRET_DIR", "value": "/var/run/secrets/notifications"}, container["env"])
            self.assertFalse(any("persistentVolumeClaim" in v for v in pod["volumes"]))
            projected = next(v["projected"] for v in pod["volumes"] if "projected" in v)
            files = {item["path"]: (source["secret"]["name"], item["key"]) for source in projected["sources"] for item in source["secret"]["items"]}
            self.assertEqual(files, {
                "api-token": ("example-api", "token"), "mysql-user": ("example-db", "user"), "mysql-password": ("example-db", "password"),
                "slack-url": ("example-channels", "slack"), "teams-url": ("example-channels", "teams"),
                "opsgenie-key": ("example-channels", "alerts"),
            })

    def test_retry_window_survives_a_twenty_minute_competing_job(self):
        # Kubernetes Job retries start at 10s with exponential delay. Test both
        # historically documented 6min and newer 10min caps; deadline must also
        # leave time for the digest to do its own source+delivery work.
        for document in self.render():
            if document['kind'] != 'CronJob':
                continue
            job = document['spec']['jobTemplate']['spec']
            for cap in (360, 600):
                attempts, elapsed = [0], 0
                for index in range(job['backoffLimit']):
                    elapsed += min(cap, 10 * 2 ** index)
                    attempts.append(elapsed)
                available = [t for t in attempts if t >= 1280 and t + 1280 < job['activeDeadlineSeconds']]
                self.assertTrue(available, 'digest can exhaust retries/deadline before competing poll releases lock')

    def test_custom_schedules_and_ca_mount(self):
        values = copy.deepcopy(self.values)
        values.update(pollSchedule="5 * * * *", digestSchedule="0 9 * * *", timeZone="Etc/UTC", mysqlCaSecret={"name": "example-ca", "key": "root.pem"})
        values["policy"]["mysql"]["ca_file"] = "/var/run/secrets/mysql-ca/ca.crt"
        jobs = [d for d in self.render(values) if d["kind"] == "CronJob"]
        self.assertEqual({d["spec"]["schedule"] for d in jobs}, {"5 * * * *", "0 9 * * *"})
        for job in jobs:
            self.assertEqual(job["spec"]["timeZone"], "Etc/UTC")
            volumes = job["spec"]["jobTemplate"]["spec"]["template"]["spec"]["volumes"]
            ca = next(v["secret"] for v in volumes if "secret" in v)
            self.assertEqual(ca["secretName"], "example-ca")
            self.assertEqual(ca["items"], [{"key": "root.pem", "path": "ca.crt"}])

    def test_missing_image_or_credentials_and_old_kubernetes_are_rejected(self):
        self.render(version="1.26.0", success=False)
        for path in [("image",), ("apiTokenSecret", "name"), ("mysqlCredentialsSecret", "name"), ("channelsSecret", "name")]:
            values = copy.deepcopy(self.values)
            obj = values
            for key in path[:-1]:
                obj = obj[key]
            obj[path[-1]] = ""
            with self.subTest(path=path):
                self.render(values, success=False)
        self.render(release="x" * 46, success=False)

    def test_single_opsgenie_key_is_the_only_opsgenie_mount(self):
        values = copy.deepcopy(self.values)
        values["channelsSecret"] = {"name": "example-channels", "slackKey": "slack-url", "teamsKey": "teams-url", "opsgenieKey": "opsgenie-key"}
        for document in self.render(values):
            if document["kind"] != "CronJob":
                continue
            volumes = document["spec"]["jobTemplate"]["spec"]["template"]["spec"]["volumes"]
            sources = [source["secret"] for volume in volumes if "projected" in volume for source in volume["projected"]["sources"]]
            source = next(source for source in sources if source["name"] == "example-channels")
            self.assertEqual(source["items"], [{"key": key, "path": key} for key in ["slack-url", "teams-url", "opsgenie-key"]])

    def test_rendered_policy_passes_worker_configuration_validation(self):
        for custom_ca in [False, True]:
            values = copy.deepcopy(self.values)
            if custom_ca:
                values["mysqlCaSecret"] = {"name": "example-ca", "key": "ca.crt"}
                values["policy"]["mysql"]["ca_file"] = "/var/run/secrets/mysql-ca/ca.crt"
            config = next(d for d in self.render(values) if "policy.json" in d.get("data", {}))
            result = subprocess.run(
                [sys.executable, "-c", "import json,sys; from notifier.config import validate; validate(json.load(sys.stdin))"],
                input=config["data"]["policy.json"], capture_output=True, text=True,
                env=dict(os.environ, PYTHONPATH=str(ROOT / "notifier")),
            )
            self.assertEqual(result.returncode, 0, result.stderr)

    def test_source_and_binary_dependencies_match_bundled_files(self):
        docs = self.render()
        sources = next(d for d in docs if "__init__.py" in d.get("data", {}))
        wheels = next(d for d in docs if "binaryData" in d)
        self.assertEqual(sources["data"], self.values["sourceFiles"])
        self.assertEqual(wheels["binaryData"], self.values["wheelFiles"])
        for document in [sources, wheels]:
            self.assertLess(len(json.dumps(document).encode()), 1024 * 1024)

    def test_only_managed_mode_creates_explicit_schema_init_hook(self):
        values = copy.deepcopy(self.values)
        values["managedMysql"] = True
        jobs = [d for d in self.render(values) if d["kind"] == "Job"]
        self.assertEqual(len(jobs), 1)
        job = jobs[0]
        self.assertIn("post-install", job["metadata"]["annotations"]["helm.sh/hook"])
        self.assertIn("post-upgrade", job["metadata"]["annotations"]["helm.sh/hook"])
        self.assertEqual(job["spec"]["template"]["spec"]["containers"][0]["command"], ["python", "-m", "notifier", "init-db"])
        self.assertFalse(job["spec"]["template"]["spec"]["automountServiceAccountToken"])


class NotificationTerraformTests(unittest.TestCase):
    def test_disabled_baseline_enabled_policy_and_invalid_inputs(self):
        if not shutil.which("terraform") or not (ROOT / ".terraform/providers").exists():
            self.skipTest("Terraform with initialized Helm provider required for offline plan checks")
        version = subprocess.check_output(["terraform", "version", "-json"], text=True)
        if tuple(int(p) for p in json.loads(version)["terraform_version"].split(".")[:2]) < (1, 7):
            self.skipTest("Terraform >=1.7 required for offline mock-provider test fixture; module remains >=1.3")
        good = {
            "enabled": True, "image": "example/notifier:review", "api_url": "https://defectdojo.example.com/", "engagement_ids": [9, 7],
            "api_token_secret": {"name": "example-api"}, "mysql": {"create": False, "host": "mysql.example.com", "database": "notifications", "credentials_secret": {"name": "example-db"}},
            "channels_secret": {"name": "example-channels"},
        }
        fixture = '''mock_provider "helm" {}\nrun "disabled" {\n command = plan\n assert {\n condition = length(helm_release.notifications) == 0 && length(helm_release.notifications_mysql) == 0 && length(helm_release.notifications_mysql_bootstrap) == 0 && length(helm_release.notifications_api_bootstrap) == 0 && length(helm_release.retention) == 0 && length(helm_release.retention_bootstrap) == 0\n error_message = "Disabled notifications must preserve existing resource count."\n }\n}\n'''
        checks = [
            'length(helm_release.notifications) == 1 && length(helm_release.notifications_mysql) == 0 && length(helm_release.notifications_mysql_bootstrap) == 0',
            '!jsondecode(helm_release.notifications[0].values[0]).managedMysql',
            '!contains(keys(var.notifications), "dry_run") && !contains(keys(output.notifications), "dry_run") && !contains(keys(jsondecode(helm_release.notifications[0].values[0]).policy), "dry_run")',
            'length(jsondecode(helm_release.notifications[0].values[0]).policy.namespace) == 64',
            '!contains(keys(jsondecode(helm_release.notifications[0].values[0]).policy.mysql), "ca_file")',
            'jsondecode(helm_release.notifications[0].values[0]).policy.mysql.tls',
            'jsondecode(helm_release.notifications[0].values[0]).pollSchedule == "0 * * * *"',
            'jsondecode(helm_release.notifications[0].values[0]).digestSchedule == "30 13 * * *" && jsondecode(helm_release.notifications[0].values[0]).timeZone == "UTC" && jsondecode(helm_release.notifications[0].values[0]).policy.time_zone == "UTC"',
            'jsondecode(helm_release.notifications[0].values[0]).policy.namespace == sha256(jsonencode([var.namespace, var.name, "https://defectdojo.example.com"]))',
            'length(helm_release.this.values) == 2 && helm_release.this.version == var.chart_version',
        ]
        fixture += 'run "enabled" {\n command = plan\n variables {\n notifications = ' + json.dumps(good) + '\n }\n'
        for check in checks:
            fixture += ' assert {\n condition = ' + check + '\n error_message = "Enabled policy contract changed."\n }\n'
        fixture += '}\n'
        alternate = copy.deepcopy(good)
        alternate["engagement_ids"] = []
        alternate["all_engagements"] = True
        alternate["time_zone"] = "UTC"
        alternate["poll_schedule"] = "0,15,30,45 8-18/2 * * 1-5"
        alternate["mysql"]["ca_secret"] = {"name": "example-ca"}
        fixture += 'run "all_scope_and_ca" {\n command = plan\n variables {\n notifications = ' + json.dumps(alternate) + '\n }\n assert {\n condition = jsondecode(helm_release.notifications[0].values[0]).policy.all_engagements && jsondecode(helm_release.notifications[0].values[0]).policy.mysql.ca_file == "/var/run/secrets/mysql-ca/ca.crt"\n error_message = "Explicit all scope and CA policy must be preserved."\n }\n}\n'
        managed = {
            "enabled": True, "api_url": "https://defectdojo.example.com/", "engagement_ids": [7],
            "api_token_secret": {"name": "example-api"}, "channels_secret": {"name": "example-channels"},
        }
        managed_checks = [
            'length(helm_release.notifications) == 1 && length(helm_release.notifications_mysql) == 1 && length(helm_release.notifications_mysql_bootstrap) == 1',
            '!jsondecode(helm_release.notifications_mysql_bootstrap[0].values[0]).retainState && !output.notifications.retain_state',
            'helm_release.notifications_mysql[0].wait && helm_release.notifications_mysql_bootstrap[0].wait',
            'jsondecode(helm_release.notifications[0].values[0]).managedMysql',
            'jsondecode(helm_release.notifications[0].values[0]).policy.mysql.host == "defectdojo-notifications-mysql.defectdojo.svc"',
            'jsondecode(helm_release.notifications[0].values[0]).policy.mysql.port == 3306 && jsondecode(helm_release.notifications[0].values[0]).policy.mysql.database == "defectdojo_notifications"',
            'jsondecode(helm_release.notifications[0].values[0]).policy.mysql.tls && jsondecode(helm_release.notifications[0].values[0]).policy.mysql.ca_file == "/var/run/secrets/mysql-ca/ca.crt"',
            'jsondecode(helm_release.notifications[0].values[0]).mysqlCredentialsSecret.name == "defectdojo-notifications-mysql-credentials" && jsondecode(helm_release.notifications[0].values[0]).mysqlCaSecret.name == "defectdojo-notifications-mysql-credentials"',
            'jsondecode(helm_release.notifications_mysql_bootstrap[0].values[0]).targetSecret.name == "defectdojo-notifications-mysql-credentials"',
            'jsondecode(helm_release.notifications_mysql[0].values[0]).credentialsSecret == "defectdojo-notifications-mysql-credentials" && jsondecode(helm_release.notifications_mysql[0].values[0]).username == "notifier"',
            'jsondecode(helm_release.notifications_mysql[0].values[0]).persistence.size == "8Gi"',
            'startswith(jsondecode(helm_release.notifications[0].values[0]).image, "python:3.12-slim@sha256:")',
            'length(keys(jsondecode(helm_release.notifications[0].values[0]).sourceFiles)) >= 5 && length(keys(jsondecode(helm_release.notifications[0].values[0]).wheelFiles)) == 2',
        ]
        fixture += 'run "managed_defaults" {\n command = plan\n variables {\n notifications = ' + json.dumps(managed) + '\n }\n'
        for check in managed_checks:
            fixture += ' assert {\n condition = ' + check + '\n error_message = "Managed database and bundled runtime contract changed."\n }\n'
        fixture += '}\n'
        fixture += 'run "atomic_application_does_not_purge_failed_bootstrap" {\n command = plan\n variables {\n atomic = true\n notifications = ' + json.dumps(managed) + '\n }\n assert {\n condition = !helm_release.notifications_mysql_bootstrap[0].atomic && helm_release.notifications_mysql[0].atomic && helm_release.notifications[0].atomic && helm_release.this.atomic\n error_message = "Bootstrap must preserve failed installs instead of triggering the purge hook through automatic atomic uninstall; other releases retain atomic configuration."\n }\n}\n'
        automatic = copy.deepcopy(managed)
        automatic["api_token_secret"] = {"key": "notification-token"}
        token_cases = [
            ("notification_only_token_bootstrap", automatic, None, [
                'length(helm_release.notifications_api_bootstrap) == 1 && helm_release.notifications_api_bootstrap[0].wait',
                'helm_release.notifications_api_bootstrap[0].name == "defectdojo-notify-token"',
                '!jsondecode(helm_release.notifications_api_bootstrap[0].values[0]).keepSecret',
                'jsondecode(helm_release.notifications_api_bootstrap[0].values[0]).targetSecret.name == "defectdojo-notifications-api" && jsondecode(helm_release.notifications_api_bootstrap[0].values[0]).targetSecret.key == "notification-token"',
                'jsondecode(helm_release.notifications_api_bootstrap[0].values[0]).sourceFullname == "defectdojo" && jsondecode(helm_release.notifications_api_bootstrap[0].values[0]).applicationRelease == "defectdojo"',
                'jsondecode(helm_release.notifications[0].values[0]).apiTokenSecret.name == "defectdojo-notifications-api" && jsondecode(helm_release.notifications[0].values[0]).apiTokenSecret.key == "notification-token"',
                'output.notifications.api_token_source == "bootstrap" && output.notifications.api_token_secret.name == "defectdojo-notifications-api"',
                'toset(keys(jsondecode(helm_release.notifications_api_bootstrap[0].values[0]).targetSecret)) == toset(["name", "key"]) && toset(keys(output.notifications.api_token_secret)) == toset(["name", "key"])',
            ]),
            ("reuse_existing_retention_token", automatic, {
                "enabled": True, "api_url": "https://defectdojo.example.com", "all_engagements": True,
                "api_token_secret": {"name": "example-retention-token", "key": "retention-token"},
            }, [
                'length(helm_release.notifications_api_bootstrap) == 0 && length(helm_release.retention_bootstrap) == 0',
                'jsondecode(helm_release.notifications[0].values[0]).apiTokenSecret.name == "example-retention-token" && jsondecode(helm_release.notifications[0].values[0]).apiTokenSecret.key == "retention-token"',
                'output.notifications.api_token_source == "retention"',
            ]),
            ("reuse_generated_retention_token", automatic, {
                "enabled": True, "api_url": "https://defectdojo.example.com", "all_engagements": True,
                "api_token_secret": {"create": True, "key": "retention-generated-token"},
            }, [
                'length(helm_release.notifications_api_bootstrap) == 0 && length(helm_release.retention_bootstrap) == 1',
                'jsondecode(helm_release.notifications[0].values[0]).apiTokenSecret.name == "defectdojo-retention" && jsondecode(helm_release.notifications[0].values[0]).apiTokenSecret.key == "retention-generated-token"',
                'output.notifications.api_token_source == "retention"',
            ]),
            ("explicit_notification_token_takes_precedence", dict(managed, api_token_secret={"name": "example-explicit-api", "key": "explicit-token"}), {
                "enabled": True, "api_url": "https://defectdojo.example.com", "all_engagements": True,
                "api_token_secret": {"create": True, "key": "retention-generated-token"},
            }, [
                'length(helm_release.notifications_api_bootstrap) == 0',
                'jsondecode(helm_release.notifications[0].values[0]).apiTokenSecret.name == "example-explicit-api" && jsondecode(helm_release.notifications[0].values[0]).apiTokenSecret.key == "explicit-token"',
                'output.notifications.api_token_source == "explicit"',
            ]),
        ]
        for name, notification_config, retention_config, assertions in token_cases:
            fixture += 'run "' + name + '" {\n command = plan\n variables {\n notifications = ' + json.dumps(notification_config) + '\n'
            if retention_config is not None:
                fixture += ' retention = ' + json.dumps(retention_config) + '\n'
            fixture += ' }\n'
            for assertion in assertions:
                fixture += ' assert {\n condition = ' + assertion + '\n error_message = "API token selection/bootstrap must preserve ownership, key mappings and nonsecret references."\n }\n'
            fixture += '}\n'
        shared_retention = {"enabled": True, "api_url": "https://defectdojo.example.com", "all_engagements": True, "api_token_secret": {"name": "example-retention-token"}}
        for label, notification_url, retention_url, explicit, valid in [
            ("https_default_origin", "HTTPS://DEFECTDOJO.example.com:443/", "https://defectdojo.example.com", False, True),
            ("http_default_origin", "http://DEFECTDOJO.example.com/", "http://defectdojo.example.com:80/", False, True),
            ("different_origin_refused", "https://other.example.com", "https://defectdojo.example.com", False, False),
            ("wrong_scheme_default_port_refused", "http://defectdojo.example.com:443", "http://defectdojo.example.com", False, False),
            ("explicit_different_origin_allowed", "https://other.example.com", "https://defectdojo.example.com", True, True),
        ]:
            notification_config = dict(automatic, api_url=notification_url)
            if explicit:
                notification_config["api_token_secret"] = {"name": "example-explicit-api"}
            retention_config = dict(shared_retention, api_url=retention_url)
            fixture += 'run "' + label + '" {\n command = plan\n variables {\n notifications = ' + json.dumps(notification_config) + '\n retention = ' + json.dumps(retention_config) + '\n }\n'
            if valid:
                fixture += ' assert {\n condition = length(helm_release.notifications) == 1\n error_message = "Equivalent automatic origins or explicit caller overrides must remain valid."\n }\n'
            else:
                fixture += ' expect_failures = [helm_release.notifications]\n'
            fixture += '}\n'
        retained = dict(managed, retain_state=True)
        fixture += 'run "managed_explicit_retain" {\n command = plan\n variables {\n notifications = ' + json.dumps(retained) + '\n }\n assert {\n condition = jsondecode(helm_release.notifications_mysql_bootstrap[0].values[0]).retainState && output.notifications.retain_state\n error_message = "Explicit retain_state=true must be passed to the installed managed bootstrap hook policy."\n }\n}\n'
        unenabled = {"api_token_secret": {"name": "example-api"}}
        fixture += 'run "secrets_do_not_enable_infrastructure" {\n command = plan\n variables {\n notifications = ' + json.dumps(unenabled) + '\n }\n assert {\n condition = length(helm_release.notifications) == 0 && length(helm_release.notifications_mysql) == 0 && length(helm_release.notifications_mysql_bootstrap) == 0 && length(helm_release.notifications_api_bootstrap) == 0 && output.notifications == null\n error_message = "Providing API/channel references must not implicitly enable notification infrastructure."\n }\n}\n'
        retained_external = dict(good, retain_state=True)
        fixture += 'run "external_retain_has_no_managed_resources" {\n command = plan\n variables {\n notifications = ' + json.dumps(retained_external) + '\n }\n assert {\n condition = length(helm_release.notifications_mysql) == 0 && length(helm_release.notifications_mysql_bootstrap) == 0 && output.notifications.retain_state\n error_message = "External MySQL must never gain managed cleanup/bootstrap resources."\n }\n}\n'
        for index, mysql in enumerate([
            {"host": "mysql.example.com"}, {"credentials_secret": {"name": "example-db"}},
            {"ca_secret": {"name": "example-ca"}}, {"tls": False}, {"port": 3307},
            {"database": "unsafe;db"}, {"storage_size": "0Gi"}, {"storage_class": "BAD/name"},
        ]):
            config = dict(managed, mysql=mysql)
            fixture += 'run "invalid_managed_' + str(index) + '" {\n command = plan\n variables {\n notifications = ' + json.dumps(config) + '\n }\n expect_failures = [var.notifications]\n}\n'
        invalids = [
            {"image": ""}, {"engagement_ids": []}, {"all_engagements": True}, {"engagement_ids": [0]},
            {"api_url": "https://user:pass@example.com"}, {"poll_schedule": "61 * * * *"}, {"digest_schedule": "@daily"},
            {"poll_schedule": "*/0 * * * *"}, {"poll_schedule": "0 18-8 * * *"}, {"poll_schedule": "0 13 * * 7"},
            {"api_token_secret": {"name": "BAD/name"}},
            {"mysql": {"create": False, "host": "mysql.example.com?bad=1", "database": "notifications", "credentials_secret": {"name": "example-db"}}},
            {"mysql": {"create": False, "host": "mysql.example.com", "database": "db;DROP", "credentials_secret": {"name": "example-db"}}},
            {"mysql": {"create": False, "host": "mysql.example.com", "database": "notifications", "tls": False, "ca_secret": {"name": "example-ca"}, "credentials_secret": {"name": "example-db"}}},
        ]
        for index, changes in enumerate(invalids):
            config = dict(good, **changes)
            fixture += 'run "invalid_' + str(index) + '" {\n command = plan\n variables {\n notifications = ' + json.dumps(config) + '\n }\n expect_failures = [var.notifications]\n}\n'
        fixture += 'run "invalid_release_name" {\n command = plan\n variables {\n name = "' + "x" * 32 + '"\n notifications = ' + json.dumps(good) + '\n }\n expect_failures = [helm_release.notifications]\n}\n'
        with tempfile.TemporaryDirectory() as directory:
            directory = Path(directory)
            for path in ROOT.glob("*.tf"):
                shutil.copy(path, directory / path.name)
            shutil.copy(ROOT / ".terraform.lock.hcl", directory / ".terraform.lock.hcl")
            (directory / ".terraform").symlink_to(ROOT / ".terraform", target_is_directory=True)
            (directory / "charts").symlink_to(ROOT / "charts", target_is_directory=True)
            (directory / "notifier").symlink_to(ROOT / "notifier", target_is_directory=True)
            tests = directory / "tests"
            tests.mkdir()
            (tests / "notifications.tftest.hcl").write_text(fixture)
            result = subprocess.run(["terraform", "-chdir=" + str(directory), "test", "-no-color"], capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)


if __name__ == "__main__":
    unittest.main()
