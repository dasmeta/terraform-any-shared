"""Generated DB credentials/TLS lifecycle and Helm bootstrap tests."""
import base64
import copy
import importlib.util
import io
import json
import os
from pathlib import Path
import ssl
import subprocess
import tempfile
import unittest
from unittest.mock import Mock, patch
from urllib.error import HTTPError

from test_notifications_mysql import ROOT, render

CHART = ROOT / "charts/notifications-mysql-bootstrap"
POLICY = dict(namespace="example", release_name="example-notifications-db-init",
    target_secret="example-notifications-mysql-credentials", service_name="example-notifications-mysql",
    pvc_name="data-example-notifications-mysql-0", username="notifier")
KEYS = {"username", "password", "root-password", "ca.crt", "tls.crt", "tls.key"}


def owned_secret(data=None):
    result = {"type": "Opaque", "metadata": {"name": POLICY["target_secret"], "namespace": "example",
        "uid": "secret-uid", "resourceVersion": "1", "labels": {"app.kubernetes.io/managed-by": "Helm",
        "app.kubernetes.io/instance": POLICY["release_name"]}, "annotations": {
        "meta.helm.sh/release-name": POLICY["release_name"], "meta.helm.sh/release-namespace": "example"}}}
    if data is not None:
        result["data"] = data
    return result


class FakeKube:
    def __init__(self, secret=None, pvc=False):
        self.secret = copy.deepcopy(secret or owned_secret())
        self.pvc, self.patches, self.pvc_queries = pvc, [], []
        self.fail_patch = False

    def get_secret(self, name):
        return copy.deepcopy(self.secret)

    def pvc_exists(self, name):
        self.pvc_queries.append(name)
        return self.pvc

    def patch_secret(self, name, operations):
        self.patches.append(copy.deepcopy(operations))
        if self.fail_patch:
            raise RuntimeError("api-token secret-password do-not-log")
        for operation in operations:
            if operation["op"] == "test":
                self_value = self.secret["metadata"][operation["path"].split("/")[-1]]
                if self_value != operation["value"]:
                    raise RuntimeError("conflict")
            elif operation["path"] == "/data":
                self.secret["data"] = copy.deepcopy(operation["value"])
            else:
                self.secret["data"][operation["path"].split("/")[-1]] = operation["value"]
        self.secret["metadata"]["resourceVersion"] = "2"


class ManagedBootstrapChartTests(unittest.TestCase):
    def setUp(self):
        self.values = dict(enabled=True, retainState=True, targetSecret={"name": POLICY["target_secret"]},
            serviceName=POLICY["service_name"], namespace="example", pvcName=POLICY["pvc_name"])

    def render(self, values=None, **kwargs):
        return render("notifications-mysql-bootstrap", self.values if values is None else values,
                      POLICY["release_name"], **kwargs)

    def test_disabled_chart_renders_nothing(self):
        self.assertEqual(self.render({}), [])

    def test_kept_placeholder_has_no_credentials_and_exact_scoped_rbac(self):
        docs = self.render()
        secret = next(doc for doc in docs if doc["kind"] == "Secret")
        self.assertEqual(secret["type"], "Opaque")
        self.assertEqual(secret["metadata"]["annotations"]["helm.sh/resource-policy"], "keep")
        self.assertNotIn("data", secret)
        self.assertNotIn("stringData", secret)
        role = next(doc for doc in docs if doc["kind"] == "Role")
        self.assertEqual(role["rules"], [
            {"apiGroups": [""], "resources": ["secrets"], "resourceNames": [POLICY["target_secret"]], "verbs": ["get", "patch"]},
            {"apiGroups": [""], "resources": ["persistentvolumeclaims"], "resourceNames": [POLICY["pvc_name"]], "verbs": ["get"]}])
        config = next(doc for doc in docs if doc["kind"] == "ConfigMap")
        self.assertEqual(json.loads(config["data"]["policy.json"]), POLICY)
        self.assertNotIn("password", config["data"]["policy.json"])
        self.assertEqual(config["data"]["bootstrap.py"], (CHART / "files/bootstrap.py").read_text())

    def test_reinstall_omits_existing_retained_secret_without_rendering_its_data(self):
        template = (CHART / "templates/resources.yaml").read_text()
        self.assertIn('lookup "v1" "Secret" .Release.Namespace $secret', template)
        self.assertRegex(template, r'(?s)if not \$existing.*?kind: Secret.*?end.*?---')
        self.assertNotIn("$existing.data", template)
        self.assertNotIn("toYaml $existing", template)
        self.assertNotIn("toJson $existing", template)

    def test_job_generates_candidate_tls_without_secret_values_in_manifests(self):
        docs = self.render()
        job = next(doc for doc in docs if doc["kind"] == "Job")
        self.assertEqual(job["metadata"]["annotations"]["helm.sh/hook"], "post-install,post-upgrade")
        self.assertEqual(job["spec"]["backoffLimit"], 0)
        pod = job["spec"]["template"]["spec"]
        self.assertTrue(pod["automountServiceAccountToken"])
        self.assertEqual(pod["securityContext"]["runAsUser"], 65532)
        self.assertEqual(pod["securityContext"]["fsGroup"], 65532)
        self.assertTrue(pod["securityContext"]["runAsNonRoot"])
        self.assertEqual(len(pod["initContainers"]), 1)
        init = pod["initContainers"][0]
        self.assertRegex(init["image"], r"^mysql:8\.4@sha256:[a-f0-9]{64}$")
        self.assertEqual(init["command"], ["bash", "/config/generate-tls.sh"])
        container = pod["containers"][0]
        self.assertEqual(container["command"], ["python", "-B", "/config/bootstrap.py"])
        self.assertRegex(container["image"], r"^python:3\.12-slim@sha256:[a-f0-9]{64}$")
        for item in (init, container):
            self.assertTrue(item["securityContext"]["readOnlyRootFilesystem"])
            self.assertFalse(item["securityContext"]["allowPrivilegeEscalation"])
            self.assertEqual(item["securityContext"]["capabilities"]["drop"], ["ALL"])
            self.assertIn({"name": "work", "mountPath": "/work"}, item["volumeMounts"])
        self.assertIn({"name": "work", "emptyDir": {"medium": "Memory", "sizeLimit": "16Mi"}}, pod["volumes"])


class BootstrapLifecycleTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.directory = tempfile.TemporaryDirectory()
        cls.tls = Path(cls.directory.name)
        # Fixture certificates are generated independently of chart implementation.
        def openssl(*args):
            subprocess.run(["openssl", *args], cwd=cls.tls, check=True, capture_output=True)
        openssl("req", "-x509", "-newkey", "rsa:2048", "-nodes", "-keyout", "ca.key", "-out", "ca.crt",
                "-subj", "/CN=Test CA", "-days", "2", "-addext", "basicConstraints=critical,CA:TRUE")
        openssl("req", "-newkey", "rsa:2048", "-nodes", "-keyout", "tls.key", "-out", "server.csr", "-subj", "/CN=example-notifications-mysql")
        (cls.tls / "extensions.cnf").write_text("basicConstraints=critical,CA:FALSE\nkeyUsage=critical,digitalSignature,keyEncipherment\nextendedKeyUsage=serverAuth\nsubjectAltName=DNS:example-notifications-mysql,DNS:example-notifications-mysql.example,DNS:example-notifications-mysql.example.svc,DNS:example-notifications-mysql.example.svc.cluster.local\n")
        openssl("x509", "-req", "-in", "server.csr", "-CA", "ca.crt", "-CAkey", "ca.key", "-CAcreateserial", "-out", "tls.crt", "-days", "1", "-extfile", "extensions.cnf")
        # A valid but expired pair for explicit renewal recovery.
        openssl("x509", "-req", "-in", "server.csr", "-CA", "ca.crt", "-CAkey", "ca.key", "-CAcreateserial", "-out", "expired.crt", "-days", "0", "-extfile", "extensions.cnf")

    @classmethod
    def tearDownClass(cls):
        cls.directory.cleanup()

    def setUp(self):
        self.assertTrue((CHART / "files/bootstrap.py").is_file(), "bootstrap implementation is missing")
        spec = importlib.util.spec_from_file_location("notifications_mysql_bootstrap", CHART / "files/bootstrap.py")
        self.mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.mod)
        self.kube = FakeKube()
        self.random = Mock(side_effect=["p" * 48, "r" * 48])

    def bootstrap(self, kube=None, policy=None):
        return self.mod.Bootstrap(kube or self.kube, policy or POLICY, self.tls, random_token=self.random)

    def complete_data(self):
        values = {"username": "notifier", "password": "p" * 48, "root-password": "r" * 48}
        values.update({key: (self.tls / key).read_text() for key in ("ca.crt", "tls.crt", "tls.key")})
        return {key: base64.b64encode(value.encode()).decode() for key, value in values.items()}

    def test_empty_secret_gets_all_keys_in_one_compare_and_swap(self):
        self.assertEqual(self.bootstrap().run(), "created")
        self.assertEqual(self.kube.pvc_queries, [POLICY["pvc_name"]])
        self.assertEqual(len(self.kube.patches), 1)
        operations = self.kube.patches[0]
        self.assertEqual(operations[:2], [{"op": "test", "path": "/metadata/uid", "value": "secret-uid"},
            {"op": "test", "path": "/metadata/resourceVersion", "value": "1"}])
        self.assertEqual(operations[2]["path"], "/data")
        self.assertEqual(set(operations[2]["value"]), KEYS)
        self.assertNotIn("ca.key", operations[2]["value"])
        self.assertEqual(base64.b64decode(self.kube.secret["data"]["username"]), b"notifier")
        self.assertEqual(self.random.call_count, 2)

    def test_complete_secret_is_reused_without_rotation_or_pvc_check(self):
        kube = FakeKube(owned_secret(self.complete_data()), pvc=True)
        self.assertEqual(self.bootstrap(kube).run(), "reused")
        self.assertEqual(kube.patches, [])
        self.assertEqual(kube.pvc_queries, [])
        self.random.assert_not_called()

    def test_empty_secret_with_existing_pvc_requires_credentials_recovery(self):
        self.kube.pvc = True
        with self.assertRaisesRegex(self.mod.BootstrapError, "credentials_recovery_required"):
            self.bootstrap().run()
        self.assertEqual(self.kube.patches, [])
        self.random.assert_not_called()

    def test_partial_malformed_or_wrong_username_secret_fails_closed(self):
        cases = [{"password": ""}, {"password": "cGFzc3dvcmQ="}, self.complete_data()]
        cases[2]["username"] = base64.b64encode(b"root").decode()
        cases.append(dict(self.complete_data(), **{"tls.crt": "not-base64"}))
        cases.append(dict(self.complete_data(), **{"tls.key": base64.b64encode(b"not PEM").decode()}))
        for data in cases:
            kube = FakeKube(owned_secret(data))
            with self.assertRaises(self.mod.BootstrapError):
                self.bootstrap(kube).run()
            self.assertEqual(kube.patches, [])
        self.random.assert_not_called()

    def test_foreign_secret_wrong_identity_and_recreated_secret_are_rejected(self):
        for field in ("uid", "resourceVersion"):
            secret = owned_secret()
            secret["metadata"][field] = ""
            with self.assertRaises(self.mod.BootstrapError):
                self.bootstrap(FakeKube(secret)).run()
        secret = owned_secret()
        secret["metadata"]["annotations"]["meta.helm.sh/release-name"] = "other-release"
        with self.assertRaises(self.mod.BootstrapError):
            self.bootstrap(FakeKube(secret)).run()
        kube = FakeKube()
        original_patch = kube.patch_secret
        def recreated(name, operations):
            original_patch(name, operations)
            kube.secret["metadata"]["uid"] = "replaced"
        kube.patch_secret = recreated
        with self.assertRaisesRegex(self.mod.BootstrapError, "secret_confirmation_failed"):
            self.bootstrap(kube).run()

    def test_cas_failure_is_not_retried_and_does_not_expose_credentials(self):
        self.kube.fail_patch = True
        with self.assertRaises(self.mod.BootstrapError) as caught:
            self.bootstrap().run()
        self.assertEqual(len(self.kube.patches), 1)
        self.assertNotIn("secret-password", repr(caught.exception))
        self.assertIsNone(caught.exception.__cause__)

    def test_normal_bootstrap_rejects_expired_tls_but_renewal_preserves_passwords(self):
        data = self.complete_data()
        data["tls.crt"] = base64.b64encode((self.tls / "expired.crt").read_bytes()).decode()
        kube = FakeKube(owned_secret(data), pvc=True)
        with self.assertRaises(self.mod.BootstrapError):
            self.bootstrap(kube).run()
        self.assertEqual(self.bootstrap(kube).run(mode="renew-tls"), "renewed")
        ops = kube.patches[0]
        self.assertEqual({op["path"] for op in ops[2:]}, {"/data/ca.crt", "/data/tls.crt", "/data/tls.key"})
        for key in ("username", "password", "root-password"):
            self.assertEqual(kube.secret["data"][key], data[key])
        self.random.assert_not_called()

    def test_tls_renewal_requires_complete_existing_secret(self):
        with self.assertRaisesRegex(self.mod.BootstrapError, "renewal_requires_complete_secret"):
            self.bootstrap().run(mode="renew-tls")
        self.assertEqual(self.kube.patches, [])

    def test_changed_secret_after_patch_fails_confirmation_without_retry(self):
        original_patch = self.kube.patch_secret
        def changed(name, operations):
            original_patch(name, operations)
            self.kube.secret["data"]["password"] = base64.b64encode(b"changed-after-patch").decode()
        self.kube.patch_secret = changed
        with self.assertRaisesRegex(self.mod.BootstrapError, "secret_confirmation_failed"):
            self.bootstrap().run()
        self.assertEqual(len(self.kube.patches), 1)

    def test_wrong_ca_and_mismatched_private_key_fail_without_mutation(self):
        for key, path in (("ca.crt", "tls.crt"), ("tls.key", "ca.key")):
            data = self.complete_data()
            data[key] = base64.b64encode((self.tls / path).read_bytes()).decode()
            kube = FakeKube(owned_secret(data))
            with self.assertRaisesRegex(self.mod.BootstrapError, "invalid_tls"):
                self.bootstrap(kube).run()
            self.assertEqual(kube.patches, [])

    def test_invalid_policy_does_not_query_or_patch_secret(self):
        for config in (dict(POLICY, namespace="other/namespace"), dict(POLICY, username="root"),
                       dict(POLICY, service_name="other.example"), dict(POLICY, extra="invalid")):
            with self.assertRaisesRegex(self.mod.BootstrapError, "invalid_policy"):
                self.bootstrap(policy=config).run()
        self.assertEqual(self.kube.patches, [])

    def test_kubernetes_transport_uses_ca_bearer_exact_paths_and_cas_patch_type(self):
        opener = Mock()
        def reply(value, code=200):
            result = io.BytesIO(json.dumps(value).encode())
            result.code = code
            return result
        opener.open.side_effect = [reply(owned_secret()), reply({}), reply({}, 404),
            reply({"metadata": {"name": POLICY["pvc_name"], "namespace": "example", "uid": "pvc-uid"}})]
        with patch.object(self.mod, "build_opener", return_value=opener) as build:
            kube = self.mod.KubeAPI("https://kubernetes.example", "example", "bearer-token", self.tls / "ca.crt")
            self.assertEqual(kube.get_secret(POLICY["target_secret"])["type"], "Opaque")
            operations = [{"op": "test", "path": "/metadata/uid", "value": "secret-uid"}]
            kube.patch_secret(POLICY["target_secret"], operations)
            self.assertFalse(kube.pvc_exists(POLICY["pvc_name"]))
            self.assertTrue(kube.pvc_exists(POLICY["pvc_name"]))
        self.assertIsInstance(build.call_args.args[0], self.mod.NoRedirect)
        context = build.call_args.args[1]._context
        self.assertTrue(context.check_hostname)
        self.assertEqual(context.verify_mode, ssl.CERT_REQUIRED)
        request = opener.open.call_args_list[0].args[0]
        self.assertEqual(request.full_url, "https://kubernetes.example/api/v1/namespaces/example/secrets/" + POLICY["target_secret"])
        self.assertEqual(request.get_header("Authorization"), "Bearer bearer-token")
        self.assertEqual(opener.open.call_args_list[0].kwargs["timeout"], 15)
        request = opener.open.call_args_list[1].args[0]
        self.assertEqual(request.get_header("Content-type"), "application/json-patch+json")
        self.assertEqual(json.loads(request.data), operations)

    def test_transport_rejects_redirects_oversized_bodies_and_missing_secret(self):
        for code, raw in ((302, b"redirect-secret-password"), (200, b"x" * 262145), (404, b"missing-secret")):
            opener = Mock()
            body = io.BytesIO(raw)
            body.code = code
            opener.open.return_value = body
            with patch.object(self.mod, "build_opener", return_value=opener):
                kube = self.mod.KubeAPI("https://kubernetes.example", "example", "bearer-token", self.tls / "ca.crt")
                with self.assertRaises(self.mod.BootstrapError) as caught:
                    kube.get_secret(POLICY["target_secret"])
            self.assertTrue(body.closed)
            self.assertNotIn("secret-password", repr(caught.exception))
        body = io.BytesIO(b"private-body")
        error = HTTPError("https://kubernetes.example/secret", 403, "sensitive-error", {}, body)
        opener = Mock()
        opener.open.side_effect = error
        with patch.object(self.mod, "build_opener", return_value=opener):
            kube = self.mod.KubeAPI("https://kubernetes.example", "example", "bearer-token", self.tls / "ca.crt")
            with self.assertRaises(self.mod.BootstrapError):
                kube.get_secret(POLICY["target_secret"])
        self.assertTrue(body.closed)

    def test_cli_errors_never_print_secret_values_and_renewal_is_explicit(self):
        output = io.StringIO()
        with patch("sys.stdout", output), patch.object(self.mod, "read_file", side_effect=RuntimeError("private-password")):
            self.assertEqual(self.mod.main([]), 1)
        self.assertEqual(json.loads(output.getvalue()), {"reason": "bootstrap_aborted"})
        output = io.StringIO()
        with patch("sys.stdout", output):
            self.assertEqual(self.mod.main(["unknown-secret-command"]), 1)
        self.assertNotIn("unknown-secret-command", output.getvalue())
        output = io.StringIO()
        with patch("sys.stdout", output), patch.dict(os.environ, {"KUBERNETES_SERVICE_HOST": "10.0.0.1"}), \
                patch.object(self.mod, "read_file", side_effect=[json.dumps(POLICY), "bearer-token"]), \
                patch.object(self.mod, "KubeAPI"), patch.object(self.mod, "Bootstrap") as bootstrap:
            bootstrap.return_value.run.return_value = "renewed"
            self.assertEqual(self.mod.main(["renew-tls"]), 0)
            bootstrap.return_value.run.assert_called_once_with(mode="renew-tls")
        self.assertEqual(json.loads(output.getvalue()), {"reason": "renewed"})

    def test_ca_chain_and_service_hostname_are_verified(self):
        wrong = dict(POLICY, service_name="other-service")
        with self.assertRaisesRegex(self.mod.BootstrapError, "invalid_tls"):
            self.bootstrap(policy=wrong).run()
        self.assertEqual(self.kube.patches, [])

    def test_generated_script_creates_expected_service_sans_and_verifiable_chain(self):
        script = CHART / "files/generate-tls.sh"
        self.assertTrue(script.is_file())
        with tempfile.TemporaryDirectory() as directory:
            result = subprocess.run(["bash", str(script)], env=dict(os.environ, TLS_DIR=directory,
                MYSQL_SERVICE_NAME=POLICY["service_name"], MYSQL_NAMESPACE="example"), capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            text = subprocess.check_output(["openssl", "x509", "-in", directory + "/tls.crt", "-noout", "-ext", "subjectAltName"], text=True)
            for host in ("example-notifications-mysql", "example-notifications-mysql.example", "example-notifications-mysql.example.svc", "example-notifications-mysql.example.svc.cluster.local"):
                self.assertIn("DNS:" + host, text)
            subprocess.run(["openssl", "verify", "-CAfile", directory + "/ca.crt", directory + "/tls.crt"], check=True, capture_output=True)
            self.assertFalse((Path(directory) / "ca.key").exists(), "CA private signing key must be discarded")
            self.assertNotIn("PRIVATE KEY", result.stdout + result.stderr)


if __name__ == "__main__":
    unittest.main()
