"""Offline rendered-manifest checks. Requires Helm and Ruby's standard YAML parser."""

import copy
import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]


class ChartTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.directory = Path(self.temp.name)
        self.values = {
            "apiTokenSecret": {"name": "example-token", "key": "api-key"},
            "contentChecksum": "a" * 64,
            "policy": {
                "api_url": "https://defectdojo.example.com",
                "engagement_ids": [7],
                "days": 30,
                "protected_branches": [],
                "protected_environments": [],
                "max_tests_per_run": 10,
            },
        }

    def render(self, values=None, version="1.27.0", success=True):
        values_file = self.directory / "values.json"
        values_file.write_text(json.dumps(self.values if values is None else values))
        env = dict(os.environ, HELM_PLUGINS=str(self.directory / "plugins"))
        result = subprocess.run(
            [os.environ.get("HELM_BIN", "helm"), "template", "example-retention", str(ROOT / "charts/retention"),
             "--namespace", "example", "--kube-version", version, "-f", str(values_file)],
            capture_output=True, text=True, env=env,
        )
        if not success:
            self.assertNotEqual(result.returncode, 0)
            return
        self.assertEqual(result.returncode, 0, result.stderr)
        manifest = self.directory / "rendered.yaml"
        manifest.write_text(result.stdout)
        output = subprocess.check_output(
            ["ruby", "-ryaml", "-rjson", "-e", "puts JSON.generate(YAML.load_stream(File.read(ARGV[0])).compact)", str(manifest)], text=True,
        )
        return {item["kind"]: item for item in json.loads(output)}

    def test_only_bounded_cronjob_and_configmap_are_created(self):
        docs = self.render()
        self.assertEqual(set(docs), {"ConfigMap", "CronJob"})
        cron = docs["CronJob"]["spec"]
        self.assertEqual(cron["concurrencyPolicy"], "Forbid")
        self.assertEqual(cron["timeZone"], "Etc/UTC")
        job = cron["jobTemplate"]["spec"]
        self.assertEqual(job["backoffLimit"], 0)
        self.assertLessEqual(job["activeDeadlineSeconds"], 3600)
        self.assertGreater(job["ttlSecondsAfterFinished"], 0)

    def test_worker_has_no_cluster_token_or_writeable_root(self):
        pod = self.render()["CronJob"]["spec"]["jobTemplate"]["spec"]["template"]["spec"]
        self.assertFalse(pod["automountServiceAccountToken"])
        self.assertTrue(pod["securityContext"]["runAsNonRoot"])
        container = pod["containers"][0]
        self.assertTrue(container["securityContext"]["readOnlyRootFilesystem"])
        self.assertFalse(container["securityContext"]["allowPrivilegeEscalation"])
        self.assertEqual(container["securityContext"]["capabilities"]["drop"], ["ALL"])
        self.assertIn("@sha256:", container["image"])
        self.assertEqual(len(container["image"].split("@sha256:")[1]), 64)
        self.assertEqual(set(container["resources"]), {"requests", "limits"})
        secret = next(v["secret"] for v in pod["volumes"] if "secret" in v)
        self.assertEqual(secret["secretName"], "example-token")
        self.assertEqual(secret["items"], [{"key": "api-key", "path": "token"}])

    def test_packaged_worker_and_policy_match_sources(self):
        docs = self.render()
        worker = (ROOT / "charts/retention/files/retention.py").read_text()
        data = docs["ConfigMap"]["data"]
        self.assertEqual(data["retention.py"].rstrip(), worker.rstrip())
        self.assertEqual(json.loads(data["policy.json"]), self.values["policy"])
        annotations = docs["CronJob"]["spec"]["jobTemplate"]["spec"]["template"]["metadata"]["annotations"]
        self.assertEqual(annotations["checksum/worker"], hashlib.sha256(worker.encode()).hexdigest())

    def test_policy_change_updates_checksum(self):
        first = self.render()["CronJob"]
        changed = copy.deepcopy(self.values)
        changed["policy"]["days"] = 31
        second = self.render(changed)["CronJob"]
        def checksum(cron):
            return cron["spec"]["jobTemplate"]["spec"]["template"]["metadata"]["annotations"]["checksum/policy"]
        self.assertNotEqual(checksum(first), checksum(second))

    def test_missing_secret_is_rejected(self):
        values = copy.deepcopy(self.values)
        values["apiTokenSecret"]["name"] = ""
        self.render(values, success=False)

    def test_old_kubernetes_is_rejected(self):
        self.render(version="1.26.0", success=False)


if __name__ == "__main__":
    unittest.main()
