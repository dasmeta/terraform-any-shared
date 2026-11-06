"""Offline bootstrap manifests and cleanup privilege-isolation checks."""

import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]


class BootstrapChartTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.directory = Path(self.temp.name)
        self.values = {
            "apiUrl": "https://defectdojo.example.com",
            "sourceFullname": "example-defectdojo",
            "applicationRelease": "example",
            "targetSecret": {"name": "example-retention-token", "key": "api-key"},
            "contentChecksum": "a" * 64,
        }

    def render(self, chart="retention-bootstrap", values=None):
        path = self.directory / "values.json"
        path.write_text(json.dumps(self.values if values is None else values))
        result = subprocess.run(
            [os.environ.get("HELM_BIN", "helm"), "template", "example-token", str(ROOT / "charts" / chart),
             "--namespace", "example", "--kube-version", "1.27.0", "-f", str(path)],
            capture_output=True, text=True, env=dict(os.environ, HELM_PLUGINS=str(self.directory / "plugins")),
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        path = self.directory / "rendered.yaml"
        path.write_text(result.stdout)
        docs = json.loads(subprocess.check_output(
            ["ruby", "-ryaml", "-rjson", "-e", "puts JSON.generate(YAML.load_stream(File.read(ARGV[0])).compact)", str(path)], text=True,
        ))
        return {item["kind"]: item for item in docs}

    def test_secret_manifest_never_contains_live_token_data(self):
        docs = self.render()
        self.assertEqual(set(docs), {"Secret", "ServiceAccount", "Role", "RoleBinding", "Job", "ConfigMap"})
        secret = docs["Secret"]
        self.assertNotIn("data", secret)
        self.assertNotIn("stringData", secret)
        self.assertEqual(secret["metadata"]["name"], "example-retention-token")
        self.assertEqual(secret["metadata"]["annotations"]["helm.sh/resource-policy"], "keep")

    def test_bootstrap_rbac_writes_only_named_target_secret(self):
        docs = self.render()
        role = docs["Role"]
        self.assertEqual(role["metadata"]["namespace"], "example")
        self.assertEqual(role["rules"], [
            {"apiGroups": [""], "resources": ["secrets"], "resourceNames": ["example-retention-token"], "verbs": ["get", "patch"]},
            {"apiGroups": ["batch"], "resources": ["jobs"], "verbs": ["list"]},
        ])
        binding = docs["RoleBinding"]
        self.assertEqual(binding["subjects"], [{"kind": "ServiceAccount", "name": "example-token", "namespace": "example"}])

    def test_hook_waits_for_existing_resources_and_is_not_automatically_retried(self):
        job = self.render()["Job"]
        self.assertEqual(job["metadata"]["annotations"]["helm.sh/hook"], "post-install,post-upgrade")
        self.assertEqual(job["metadata"]["annotations"]["helm.sh/hook-delete-policy"], "before-hook-creation,hook-succeeded")
        self.assertEqual(job["spec"]["backoffLimit"], 0)
        self.assertEqual(job["spec"]["activeDeadlineSeconds"], 600)

    def test_credentials_are_projected_as_single_read_only_keys(self):
        pod = self.render()["Job"]["spec"]["template"]["spec"]
        self.assertEqual(pod["serviceAccountName"], "example-token")
        self.assertTrue(pod["automountServiceAccountToken"])
        self.assertTrue(pod["securityContext"]["runAsNonRoot"])
        volumes = {v["name"]: v for v in pod["volumes"]}
        self.assertEqual(volumes["username"]["configMap"], {"name": "example-defectdojo", "items": [{"key": "DD_ADMIN_USER", "path": "username"}]})
        self.assertEqual(volumes["password"]["secret"]["secretName"], "example-defectdojo")
        self.assertEqual(volumes["password"]["secret"]["items"], [{"key": "DD_ADMIN_PASSWORD", "path": "password"}])
        container = pod["containers"][0]
        self.assertTrue(all(v["readOnly"] for v in container["volumeMounts"]))
        self.assertTrue(container["securityContext"]["readOnlyRootFilesystem"])
        self.assertFalse(container["securityContext"]["allowPrivilegeEscalation"])

    def test_policy_and_bundled_worker_match_module_configuration(self):
        data = self.render()["ConfigMap"]["data"]
        self.assertEqual(json.loads(data["policy.json"]), {
            "api_url": "https://defectdojo.example.com", "namespace": "example", "release_name": "example-token",
            "application_release": "example", "target_secret": "example-retention-token", "target_key": "api-key",
        })
        self.assertEqual(data["bootstrap.py"].rstrip(), (ROOT / "charts/retention-bootstrap/files/bootstrap.py").read_text().rstrip())

    def test_cleanup_chart_has_no_bootstrap_credentials_or_privileges(self):
        docs = self.render("retention", {"apiTokenSecret": {"name": "example-retention-token", "key": "api-key"}, "policy": {"engagement_ids": [7]}})
        self.assertEqual(set(docs), {"ConfigMap", "CronJob"})
        pod = docs["CronJob"]["spec"]["jobTemplate"]["spec"]["template"]["spec"]
        self.assertFalse(pod["automountServiceAccountToken"])
        self.assertFalse(any(v.get("secret", {}).get("secretName") == "example-defectdojo" for v in pod["volumes"]))


if __name__ == "__main__":
    unittest.main()
