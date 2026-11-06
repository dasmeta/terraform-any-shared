"""Offline bootstrap sequencing, Secret lifecycle and token transport tests."""

import base64
import copy
import importlib.util
import io
import json
from pathlib import Path
import ssl
import subprocess
import tempfile
import threading
import unittest
from contextlib import redirect_stdout
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer


SOURCE = Path(__file__).resolve().parents[1] / "charts/retention-bootstrap/files/bootstrap.py"
spec = importlib.util.spec_from_file_location("bootstrap", SOURCE)
bootstrap = importlib.util.module_from_spec(spec)
spec.loader.exec_module(bootstrap)


def job(complete=True, failed=False, created="2026-11-05T00:00:00Z"):
    return {
        "metadata": {"namespace": "example", "creationTimestamp": created,
                     "labels": {"defectdojo.org/component": "initializer", "app.kubernetes.io/instance": "example"}},
        "status": {"conditions": [{"type": "Failed" if failed else "Complete", "status": "True"}] if complete or failed else []},
    }


class Kube:
    def __init__(self):
        self.secret = {
            "metadata": {"name": "example-token", "namespace": "example", "uid": "uid-1", "resourceVersion": "1",
                         "labels": {"app.kubernetes.io/managed-by": "Helm", "app.kubernetes.io/instance": "example-token"},
                         "annotations": {"meta.helm.sh/release-name": "example-token", "meta.helm.sh/release-namespace": "example"}},
            "type": "Opaque",
        }
        self.jobs = [[job()]]
        self.patches = []
        self.calls = []
        self.conflict = False

    def get_secret(self, name):
        self.calls.append("secret-get")
        return copy.deepcopy(self.secret)

    def list_initializers(self, release):
        self.calls.append("jobs-list")
        result = self.jobs[0]
        if len(self.jobs) > 1:
            self.jobs.pop(0)
        return copy.deepcopy(result)

    def patch_secret(self, name, operations):
        self.calls.append("secret-patch")
        self.patches.append(copy.deepcopy(operations))
        if self.conflict:
            self.secret["metadata"]["resourceVersion"] = "2"
        for op in operations:
            path = op["path"].strip("/").split("/")
            target = self.secret
            for field in path[:-1]:
                target = target[field]
            if op["op"] == "test":
                if target[path[-1]] != op["value"]:
                    raise bootstrap.BootstrapError("secret_conflict")
            elif op["op"] == "add":
                target[path[-1]] = op["value"]
            else:
                raise AssertionError(op)


class Dojo:
    def __init__(self):
        self.ready_values = [True]
        self.logins = []
        self.validations = []
        self.valid = True
        self.login_error = False

    def ready(self):
        result = self.ready_values[0]
        if len(self.ready_values) > 1:
            self.ready_values.pop(0)
        return result

    def login(self, username, password):
        self.logins.append((username, password))
        if self.login_error:
            raise bootstrap.BootstrapError("authentication_failed")
        return "new-token"

    def validate_token(self, token):
        self.validations.append(token)
        return self.valid


class BootstrapTests(unittest.TestCase):
    def setUp(self):
        self.kube, self.dojo = Kube(), Dojo()
        self.config = {"namespace": "example", "target_secret": "example-token", "target_key": "api-key",
                       "release_name": "example-token", "application_release": "example"}
        self.elapsed = 0

    def run_bootstrap(self):
        def sleep(seconds):
            self.elapsed += seconds
        runner = bootstrap.Bootstrap(self.kube, self.dojo, self.config, "admin", " password with spaces ", sleep=sleep, clock=lambda: self.elapsed)
        return runner.run()

    def test_creates_token_after_initializer_and_api_readiness(self):
        self.kube.jobs = [[job(complete=False)], [job()]]
        self.dojo.ready_values = [False, True]
        self.assertEqual(self.run_bootstrap(), "created")
        self.assertGreaterEqual(self.elapsed, 6)
        self.assertEqual(self.dojo.logins, [("admin", " password with spaces ")])
        self.assertEqual(self.dojo.validations, ["new-token"])
        self.assertEqual(len(self.kube.patches), 1)
        self.assertEqual(base64.b64decode(self.kube.secret["data"]["api-key"]), b"new-token")

    def test_reuses_valid_stored_token_without_login_or_patch(self):
        self.kube.secret["data"] = {"api-key": base64.b64encode(b"stored-token").decode()}
        self.assertEqual(self.run_bootstrap(), "reused")
        self.assertEqual(self.dojo.validations, ["stored-token"])
        self.assertEqual(self.dojo.logins, [])
        self.assertEqual(self.kube.patches, [])

    def test_invalid_existing_token_is_not_rotated(self):
        self.kube.secret["data"] = {"api-key": base64.b64encode(b"stored-token").decode()}
        self.dojo.valid = False
        with self.assertRaises(bootstrap.BootstrapError):
            self.run_bootstrap()
        self.assertEqual(self.dojo.logins, [])
        self.assertEqual(self.kube.patches, [])

    def test_malformed_existing_token_is_not_overwritten(self):
        self.kube.secret["data"] = {"api-key": "not-valid-base64!"}
        with self.assertRaises(bootstrap.BootstrapError):
            self.run_bootstrap()
        self.assertEqual(self.kube.patches, [])

    def test_foreign_secret_is_never_adopted(self):
        self.kube.secret["metadata"]["annotations"]["meta.helm.sh/release-name"] = "other"
        with self.assertRaises(bootstrap.BootstrapError):
            self.run_bootstrap()
        self.assertEqual(self.dojo.logins, [])
        self.assertEqual(self.kube.patches, [])

    def test_failed_initializer_prevents_authentication(self):
        self.kube.jobs = [[job(failed=True)]]
        with self.assertRaises(bootstrap.BootstrapError):
            self.run_bootstrap()
        self.assertEqual(self.dojo.logins, [])

    def test_ttl_deleted_initializer_is_allowed_with_ready_api(self):
        self.kube.jobs = [[]]
        self.assertEqual(self.run_bootstrap(), "created")

    def test_old_failed_initializer_does_not_override_latest_success(self):
        self.kube.jobs = [[job(failed=True, created="2026-01-01T00:00:00Z"), job()]]
        self.assertEqual(self.run_bootstrap(), "created")

    def test_initializer_timeout_prevents_authentication(self):
        self.kube.jobs = [[job(complete=False)]]
        with self.assertRaises(bootstrap.BootstrapError):
            self.run_bootstrap()
        self.assertEqual(self.dojo.logins, [])
        self.assertLessEqual(self.elapsed, 540)

    def test_api_readiness_timeout_prevents_authentication(self):
        self.dojo.ready_values = [False]
        with self.assertRaises(bootstrap.BootstrapError):
            self.run_bootstrap()
        self.assertEqual(self.dojo.logins, [])

    def test_auth_failure_is_not_retried(self):
        self.dojo.login_error = True
        with self.assertRaises(bootstrap.BootstrapError):
            self.run_bootstrap()
        self.assertEqual(len(self.dojo.logins), 1)
        self.assertEqual(self.kube.patches, [])

    def test_new_token_must_validate_before_patch(self):
        self.dojo.valid = False
        with self.assertRaises(bootstrap.BootstrapError):
            self.run_bootstrap()
        self.assertEqual(self.kube.patches, [])

    def test_secret_update_is_guarded_and_never_retried(self):
        self.kube.conflict = True
        with self.assertRaises(bootstrap.BootstrapError):
            self.run_bootstrap()
        self.assertEqual(len(self.kube.patches), 1)
        tests = {op["path"] for op in self.kube.patches[0] if op["op"] == "test"}
        self.assertEqual(tests, {"/metadata/uid", "/metadata/resourceVersion"})

    def test_other_secret_data_is_preserved(self):
        self.kube.secret["data"] = {"other": "b3RoZXI="}
        self.run_bootstrap()
        self.assertEqual(self.kube.secret["data"]["other"], "b3RoZXI=")

    def test_unscoped_job_response_fails_closed(self):
        self.kube.jobs[0][0]["metadata"]["labels"]["app.kubernetes.io/instance"] = "other"
        with self.assertRaises(bootstrap.BootstrapError):
            self.run_bootstrap()
        self.assertEqual(self.dojo.logins, [])

    def test_secrets_are_not_printed(self):
        output = io.StringIO()
        with redirect_stdout(output):
            self.run_bootstrap()
        self.assertNotIn("new-token", output.getvalue())
        self.assertNotIn("password", output.getvalue())

    def test_changed_secret_after_patch_does_not_report_success(self):
        original = self.kube.get_secret
        def changed(name):
            result = original(name)
            if self.kube.patches:
                result["data"]["api-key"] = base64.b64encode(b"different-token").decode()
            return result
        self.kube.get_secret = changed
        with self.assertRaises(bootstrap.BootstrapError):
            self.run_bootstrap()
        self.assertEqual(len(self.kube.patches), 1)

    def test_dotted_release_labels_are_supported(self):
        self.config["release_name"] = "example.token"
        self.config["application_release"] = "example.app"
        self.kube.secret["metadata"]["labels"]["app.kubernetes.io/instance"] = "example.token"
        self.kube.secret["metadata"]["annotations"]["meta.helm.sh/release-name"] = "example.token"
        self.kube.jobs[0][0]["metadata"]["labels"]["app.kubernetes.io/instance"] = "example.app"
        self.assertEqual(self.run_bootstrap(), "created")

    def test_password_file_preserves_exact_whitespace(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "password"
            path.write_bytes(b" password\r\n")
            self.assertEqual(bootstrap.read_file(path, 100), " password\r\n")


class TransportFixture:
    def setUp(self):
        self.status = 200
        self.body = {"token": "new-token"}
        self.calls = []
        self.content_types = []
        owner = self
        class Handler(BaseHTTPRequestHandler):
            def do_POST(self):
                payload = self.rfile.read(int(self.headers.get("Content-Length", "0")))
                owner.calls.append((self.path, payload, self.headers.get("Authorization")))
                owner.content_types.append(self.headers.get("Content-Type"))
                self.send_response(owner.status)
                self.send_header("Content-Type", "application/json")
                if owner.status == 302:
                    self.send_header("Location", "/redirect-target")
                self.end_headers()
                self.wfile.write(owner.body if isinstance(owner.body, bytes) else json.dumps(owner.body).encode())
            do_GET = do_POST
            do_PATCH = do_POST
            def log_message(self, *args):
                pass
        self.server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
        threading.Thread(target=self.server.serve_forever, daemon=True).start()
        self.addCleanup(self.server.server_close)
        self.addCleanup(self.server.shutdown)
        self.url = f"http://127.0.0.1:{self.server.server_port}"


class TransportTests(TransportFixture, unittest.TestCase):
    def test_login_posts_credentials_once_to_configured_origin(self):
        self.assertEqual(bootstrap.DojoAPI(self.url).login("admin", " password "), "new-token")
        self.assertEqual(len(self.calls), 1)
        path, body, authorization = self.calls[0]
        self.assertEqual(path, "/api/v2/api-token-auth/")
        self.assertEqual(json.loads(body), {"username": "admin", "password": " password "})
        self.assertIsNone(authorization)

    def test_password_redirect_is_not_followed(self):
        self.status = 302
        with self.assertRaises(bootstrap.BootstrapError):
            bootstrap.DojoAPI(self.url).login("admin", "private-password")
        self.assertEqual(len(self.calls), 1)

    def test_auth_error_does_not_expose_body_or_password(self):
        self.status = 400
        self.body = {"error": "private-response"}
        with self.assertRaises(bootstrap.BootstrapError) as context:
            bootstrap.DojoAPI(self.url).login("admin", "private-password")
        self.assertNotIn("private", str(context.exception))
        self.assertEqual(len(self.calls), 1)

    def test_bad_token_response_is_rejected(self):
        for body in [{}, {"token": ""}, {"token": "bad\nheader"}]:
            self.body = body
            with self.assertRaises(bootstrap.BootstrapError):
                bootstrap.DojoAPI(self.url).login("admin", "password")

    def test_empty_userinfo_and_non_origin_urls_are_rejected(self):
        for url in ["https://@example.com", "https://user@example.com", "https://example.com/path", "https://example.com?query=x"]:
            with self.subTest(url=url):
                with self.assertRaises(bootstrap.BootstrapError):
                    bootstrap.DojoAPI(url)

    def test_ready_statuses_and_authenticated_token_check(self):
        for code in [200, 401, 403]:
            self.status = code
            self.assertTrue(bootstrap.DojoAPI(self.url).ready())
        for code in [404, 500, 503]:
            self.status = code
            self.assertFalse(bootstrap.DojoAPI(self.url).ready())
        self.status = 200
        self.body = {"count": 0, "results": []}
        self.assertTrue(bootstrap.DojoAPI(self.url).validate_token("offline-token"))
        self.assertEqual(self.calls[-1][0], "/api/v2/tests/?limit=1")
        self.assertEqual(self.calls[-1][2], "Token offline-token")

    def test_failed_or_malformed_token_validation_fails_closed(self):
        for code in [401, 403]:
            self.status = code
            self.assertFalse(bootstrap.DojoAPI(self.url).validate_token("offline-token"))
        self.status = 200
        for body in [{}, {"count": True, "results": []}, {"count": 1, "results": []}]:
            self.body = body
            with self.assertRaises(bootstrap.BootstrapError):
                bootstrap.DojoAPI(self.url).validate_token("offline-token")

    def test_response_and_request_budgets(self):
        client = bootstrap.DojoAPI(self.url)
        client.calls = 500
        with self.assertRaises(bootstrap.BootstrapError):
            client.ready()
        self.assertEqual(self.calls, [])
        self.body = b"x" * (2 * 1024 * 1024 + 1)
        with self.assertRaises(bootstrap.BootstrapError):
            bootstrap.DojoAPI(self.url).login("admin", "password")


class KubernetesTLSTests(TransportFixture, unittest.TestCase):
    """Exercise real HTTPS and CA verification against a temporary local server."""

    def setUp(self):
        super().setUp()
        self.cert_directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.cert_directory.cleanup)
        root = Path(self.cert_directory.name)
        config = root / "openssl.cnf"
        config.write_text('''[req]
distinguished_name=dn
x509_extensions=extensions
prompt=no
[dn]
CN=127.0.0.1
[extensions]
subjectAltName=IP:127.0.0.1
basicConstraints=critical,CA:TRUE
keyUsage=critical,keyCertSign,digitalSignature,keyEncipherment
extendedKeyUsage=serverAuth
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid:always
''')
        self.cert, key = root / "cert.pem", root / "key.pem"
        subprocess.run(["openssl", "req", "-x509", "-newkey", "rsa:2048", "-nodes", "-days", "1",
                        "-config", str(config), "-keyout", str(key), "-out", str(self.cert)],
                       check=True, capture_output=True)
        self.server.shutdown()
        context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
        context.load_cert_chain(self.cert, key)
        self.server.socket = context.wrap_socket(self.server.socket, server_side=True)
        threading.Thread(target=self.server.serve_forever, daemon=True).start()
        self.url = f"https://127.0.0.1:{self.server.server_port}"

    def test_kubernetes_get_and_conditional_patch_use_bearer_and_jsonpatch(self):
        self.body = {"kind": "Secret", "metadata": {"name": "example-token"}}
        client = bootstrap.KubeAPI(self.url, "example", "offline-sa", str(self.cert))
        self.assertEqual(client.get_secret("example-token")["kind"], "Secret")
        operations = [{"op": "test", "path": "/metadata/resourceVersion", "value": "1"}]
        client.patch_secret("example-token", operations)
        self.assertEqual(self.calls[0][0], "/api/v1/namespaces/example/secrets/example-token")
        self.assertTrue(all(call[2] == "Bearer offline-sa" for call in self.calls))
        self.assertEqual(json.loads(self.calls[-1][1]), operations)
        self.assertEqual(self.content_types[-1], "application/json-patch+json")

    def test_initializer_filter_and_truncated_list(self):
        self.body = {"items": [], "metadata": {}}
        client = bootstrap.KubeAPI(self.url, "example", "offline-sa", str(self.cert))
        self.assertEqual(client.list_initializers("example"), [])
        self.assertIn("labelSelector=", self.calls[-1][0])
        self.assertIn("defectdojo.org%2Fcomponent%3Dinitializer", self.calls[-1][0])
        self.body = {"items": [], "metadata": {"continue": "more"}}
        with self.assertRaises(bootstrap.BootstrapError):
            client.list_initializers("example")

    def test_kubernetes_ca_is_verified(self):
        with self.assertRaises(bootstrap.BootstrapError):
            bootstrap.KubeAPI(self.url, "example", "offline-sa", None).get_secret("example-token")
        self.assertEqual(self.calls, [])

    def test_unsafe_secret_path_is_rejected_without_request(self):
        client = bootstrap.KubeAPI(self.url, "example", "offline-sa", str(self.cert))
        with self.assertRaises(bootstrap.BootstrapError):
            client.get_secret("../source-password")
        self.assertEqual(self.calls, [])


if __name__ == "__main__":
    unittest.main()
