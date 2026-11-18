"""Offline managed MySQL chart checks; never deploys a server."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


def render(chart, values, release, namespace="example", version="1.27.0", success=True):
    with tempfile.TemporaryDirectory() as directory:
        values_file = Path(directory) / "values.json"
        values_file.write_text(json.dumps(values))
        result = subprocess.run([os.environ.get("HELM_BIN", "helm"), "template", release,
            str(ROOT / "charts" / chart), "--namespace", namespace, "--kube-version", version,
            "-f", str(values_file)], text=True, capture_output=True,
            env=dict(os.environ, HELM_PLUGINS=str(Path(directory) / "plugins")))
        if not success:
            if result.returncode == 0:
                raise AssertionError("invalid chart configuration rendered")
            return []
        if result.returncode:
            raise AssertionError(result.stderr)
        manifest = Path(directory) / "rendered.yaml"
        manifest.write_text(result.stdout)
        output = subprocess.check_output(["ruby", "-ryaml", "-rjson", "-e",
            "puts JSON.generate(YAML.load_stream(File.read(ARGV[0])).compact)", str(manifest)], text=True)
        return json.loads(output)


class ManagedMySQLChartTests(unittest.TestCase):
    def setUp(self):
        self.values = dict(enabled=True, credentialsSecret="example-notifications-mysql-credentials",
            database="defectdojo_notifications", username="notifier", workerRelease="example-notifications")

    def render(self, values=None, **kwargs):
        return render("notifications-mysql", self.values if values is None else values,
                      "example-notifications-mysql", **kwargs)

    def test_disabled_renders_nothing(self):
        self.assertEqual(self.render({}), [])

    def test_single_persistent_nonpublic_database_with_required_tls(self):
        docs = self.render()
        self.assertEqual(sorted(doc["kind"] for doc in docs), ["NetworkPolicy", "Service", "StatefulSet"])
        stateful = next(doc for doc in docs if doc["kind"] == "StatefulSet")
        self.assertEqual(stateful["spec"]["replicas"], 1)
        self.assertEqual(stateful["spec"]["serviceName"], "example-notifications-mysql")
        self.assertNotIn("persistentVolumeClaimRetentionPolicy", stateful["spec"])
        claim = stateful["spec"]["volumeClaimTemplates"][0]
        self.assertEqual(claim["spec"]["resources"]["requests"]["storage"], "8Gi")
        self.assertNotIn("storageClassName", claim["spec"])
        pod = stateful["spec"]["template"]["spec"]
        self.assertFalse(pod["automountServiceAccountToken"])
        self.assertEqual(pod["securityContext"]["runAsUser"], 999)
        self.assertEqual(pod["securityContext"]["fsGroup"], 999)
        container = pod["containers"][0]
        self.assertRegex(container["image"], r"^mysql:8\.4[^@]*@sha256:[a-f0-9]{64}$")
        self.assertTrue(container["securityContext"]["readOnlyRootFilesystem"])
        self.assertFalse(container["securityContext"]["allowPrivilegeEscalation"])
        self.assertEqual(container["securityContext"]["capabilities"]["drop"], ["ALL"])
        self.assertIn("--require-secure-transport=ON", container["args"])
        self.assertIn("--ssl-ca=/run/mysql-secrets/ca.crt", container["args"])
        self.assertIn("--ssl-cert=/run/mysql-secrets/tls.crt", container["args"])
        self.assertIn("--ssl-key=/run/mysql-secrets/tls.key", container["args"])
        self.assertIn("--datadir=/var/lib/mysql/data", container["args"])
        env = {value["name"]: value.get("value") for value in container["env"]}
        self.assertEqual(env["MYSQL_ROOT_HOST"], "localhost")
        self.assertEqual(env["MYSQL_ROOT_PASSWORD_FILE"], "/run/mysql-secrets/root-password")
        self.assertEqual(env["MYSQL_PASSWORD_FILE"], "/run/mysql-secrets/password")
        self.assertEqual(env["MYSQL_DATABASE"], "defectdojo_notifications")
        self.assertEqual(env["MYSQL_USER"], "notifier")
        self.assertNotIn("MYSQL_ROOT_PASSWORD", env)
        self.assertNotIn("MYSQL_PASSWORD", env)
        self.assertTrue(all(probe in container for probe in ("startupProbe", "readinessProbe", "livenessProbe")))
        mounts = {mount["mountPath"]: mount for mount in container["volumeMounts"]}
        self.assertTrue(mounts["/run/mysql-secrets"]["readOnly"])
        self.assertIn("/tmp", mounts)
        self.assertIn("/var/run/mysqld", mounts)
        secret = next(volume["secret"] for volume in pod["volumes"] if "secret" in volume)
        self.assertEqual(secret["secretName"], self.values["credentialsSecret"])
        service = next(doc for doc in docs if doc["kind"] == "Service")
        self.assertEqual(service["spec"]["clusterIP"], "None")
        self.assertNotIn("externalIPs", service["spec"])
        self.assertNotIn("nodePort", service["spec"]["ports"][0])

    def test_startup_paths_are_writable_and_readiness_waits_for_tls_tcp_server(self):
        pod = next(doc for doc in self.render() if doc["kind"] == "StatefulSet")["spec"]["template"]["spec"]
        container = pod["containers"][0]
        self.assertIn("--log-error=/var/run/mysqld/mysql-error.log", container["args"])
        # Startup logging must not prepopulate the datadir before --initialize.
        self.assertFalse(any(arg.startswith("--log-error=/var/lib/mysql/") for arg in container["args"]))
        self.assertIn("--secure-file-priv=NULL", container["args"])
        self.assertIn("--mysqlx=OFF", container["args"])
        ready = container["readinessProbe"]["exec"]["command"][-1]
        self.assertIn("--protocol=tcp", ready)
        self.assertIn("--host=127.0.0.1", ready)
        self.assertIn("--ssl-mode=VERIFY_CA", ready)
        self.assertIn("--ssl-ca=/run/mysql-secrets/ca.crt", ready)
        self.assertNotIn("--protocol=socket", ready)

    def test_database_names_match_existing_safe_identifier_contract(self):
        for database in ("1notifications", "_notifications"):
            docs = self.render(dict(self.values, database=database))
            container = next(doc for doc in docs if doc["kind"] == "StatefulSet")["spec"]["template"]["spec"]["containers"][0]
            self.assertIn({"name": "MYSQL_DATABASE", "value": database}, container["env"])

    def test_network_policy_admits_only_same_namespace_notification_pods(self):
        policy = next(doc for doc in self.render() if doc["kind"] == "NetworkPolicy")["spec"]
        self.assertEqual(policy["policyTypes"], ["Ingress"])
        self.assertEqual(policy["ingress"], [{"from": [{"podSelector": {"matchLabels": {
            "app.kubernetes.io/name": "defectdojo-notifications",
            "app.kubernetes.io/instance": "example-notifications"}}}],
            "ports": [{"protocol": "TCP", "port": 3306}]}])

    def test_custom_storage_class_and_size(self):
        docs = self.render(dict(self.values, persistence={"size": "16Gi", "storageClass": "example-csi"}))
        claim = next(doc for doc in docs if doc["kind"] == "StatefulSet")["spec"]["volumeClaimTemplates"][0]
        self.assertEqual(claim["spec"]["storageClassName"], "example-csi")
        self.assertEqual(claim["spec"]["resources"]["requests"]["storage"], "16Gi")

    def test_explicit_empty_storage_class_disables_default_provisioner(self):
        docs = self.render(dict(self.values, persistence={"size": "8Gi", "storageClass": ""}))
        claim = next(doc for doc in docs if doc["kind"] == "StatefulSet")["spec"]["volumeClaimTemplates"][0]
        self.assertIn("storageClassName", claim["spec"])
        self.assertEqual(claim["spec"]["storageClassName"], "")

    def test_missing_required_values_and_old_cluster_fail(self):
        for key in ("credentialsSecret", "workerRelease", "database"):
            self.render(dict(self.values, **{key: ""}), success=False)
        self.render(version="1.26.0", success=False)


if __name__ == "__main__":
    unittest.main()
