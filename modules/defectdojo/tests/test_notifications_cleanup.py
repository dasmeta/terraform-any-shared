"""Fake-only managed DB teardown, exact ownership and uninstall hook regressions."""
import copy
import importlib.util
import io
import json
from pathlib import Path
import sys
import unittest
from unittest.mock import Mock, patch
from urllib.error import HTTPError

from test_notifications_mysql import ROOT, render
from test_notifications_mysql_bootstrap import POLICY, owned_secret

CHART = ROOT / "charts/notifications-mysql-bootstrap"


def pvc(uid="pvc-uid", version="1"):
    return {"kind": "PersistentVolumeClaim", "metadata": {"name": POLICY["pvc_name"], "namespace": "example",
        "uid": uid, "resourceVersion": version, "labels": {
        "app.kubernetes.io/name": "defectdojo-notifications-mysql",
        "app.kubernetes.io/instance": POLICY["service_name"]}}}


def pod(uid="pod-uid"):
    return {"kind": "Pod", "metadata": {"name": POLICY["service_name"] + "-0", "namespace": "example",
        "uid": uid, "resourceVersion": "1"}}


class Clock:
    def __init__(self):
        self.now = 0

    def time(self):
        return self.now

    def sleep(self, seconds):
        self.now += seconds


class FakeAPI:
    def __init__(self, pvcs=None, secrets=None, pods=None, statefulsets=None):
        self.sequences = {"pvc": list(pvcs if pvcs is not None else [pvc(), None]),
            "secret": list(secrets if secrets is not None else [owned_secret(), owned_secret(), None]),
            "pod": list(pods if pods is not None else [None]),
            "statefulset": list(statefulsets if statefulsets is not None else [None])}
        self.calls = []
        self.fail_delete = None

    def get(self, kind, name):
        self.calls.append(("GET", kind, name))
        sequence = self.sequences[kind]
        result = sequence.pop(0) if len(sequence) > 1 else sequence[0]
        if isinstance(result, Exception):
            raise result
        return copy.deepcopy(result)

    def delete(self, kind, name, preconditions):
        self.calls.append(("DELETE", kind, name, dict(preconditions)))
        if self.fail_delete == kind:
            raise RuntimeError("Forbidden credential-secret response")


class CleanupChartTests(unittest.TestCase):
    def setUp(self):
        self.values = dict(enabled=True, targetSecret={"name": POLICY["target_secret"]},
            serviceName=POLICY["service_name"], namespace="example", pvcName=POLICY["pvc_name"])

    def render(self, retain=None):
        values = dict(self.values)
        if retain is not None:
            values["retainState"] = retain
        return render("notifications-mysql-bootstrap", values, POLICY["release_name"])

    def test_default_purge_adds_scoped_hook_and_delete_permissions(self):
        docs = self.render()
        cleanup = next((doc for doc in docs if doc["kind"] == "Job" and doc["metadata"]["annotations"]["helm.sh/hook"] == "pre-delete"), None)
        self.assertIsNotNone(cleanup, "purge pre-delete hook is missing")
        self.assertEqual(cleanup["metadata"]["annotations"]["helm.sh/hook-delete-policy"], "before-hook-creation,hook-succeeded")
        self.assertGreaterEqual(cleanup["spec"]["activeDeadlineSeconds"], 600)
        self.assertLessEqual(cleanup["spec"]["backoffLimit"], 2)
        pod_spec = cleanup["spec"]["template"]["spec"]
        self.assertNotIn("initContainers", pod_spec)
        self.assertEqual(pod_spec["serviceAccountName"], POLICY["release_name"])
        self.assertTrue(pod_spec["automountServiceAccountToken"])
        self.assertEqual(pod_spec["securityContext"]["runAsUser"], 65532)
        container = pod_spec["containers"][0]
        self.assertEqual(container["command"], ["python", "-B", "/config/cleanup.py"])
        self.assertTrue(container["securityContext"]["readOnlyRootFilesystem"])
        self.assertEqual(container["volumeMounts"], [{"name": "config", "mountPath": "/config", "readOnly": True}])
        role = next(doc for doc in docs if doc["kind"] == "Role")
        self.assertEqual(role["rules"], [
            {"apiGroups": [""], "resources": ["secrets"], "resourceNames": [POLICY["target_secret"]], "verbs": ["get", "patch", "delete"]},
            {"apiGroups": [""], "resources": ["persistentvolumeclaims"], "resourceNames": [POLICY["pvc_name"]], "verbs": ["get", "delete"]},
            {"apiGroups": ["apps"], "resources": ["statefulsets"], "resourceNames": [POLICY["service_name"]], "verbs": ["get"]},
            {"apiGroups": [""], "resources": ["pods"], "resourceNames": [POLICY["service_name"] + "-0"], "verbs": ["get"]}])
        config = next(doc for doc in docs if doc["kind"] == "ConfigMap")
        self.assertEqual(config["data"]["cleanup.py"], (CHART / "files/cleanup.py").read_text())
        secret = next(doc for doc in docs if doc["kind"] == "Secret")
        self.assertEqual(secret["metadata"]["annotations"]["helm.sh/resource-policy"], "keep")
        self.assertNotIn("data", secret)

    def test_retain_mode_keeps_original_permissions_and_no_delete_hook(self):
        docs = self.render(retain=True)
        hooks = [doc["metadata"]["annotations"]["helm.sh/hook"] for doc in docs if doc["kind"] == "Job"]
        self.assertEqual(hooks, ["post-install,post-upgrade"])
        role = next(doc for doc in docs if doc["kind"] == "Role")
        self.assertEqual(len(role["rules"]), 2)
        self.assertEqual(role["rules"][0]["verbs"], ["get", "patch"])
        self.assertEqual(role["rules"][1]["verbs"], ["get"])
        self.assertNotIn("cleanup.py", next(doc for doc in docs if doc["kind"] == "ConfigMap")["data"])

    def test_existing_selector_labels_identify_pvc_without_mutating_immutable_template(self):
        docs = render("notifications-mysql", dict(enabled=True, credentialsSecret=POLICY["target_secret"],
            workerRelease="example-notifications"), POLICY["service_name"])
        claim = next(doc for doc in docs if doc["kind"] == "StatefulSet")["spec"]["volumeClaimTemplates"][0]
        # Kubernetes copies selector.MatchLabels to created PVCs. Preserve the
        # immutable volumeClaimTemplate so enabled upgrades remain valid.
        stateful = next(doc for doc in docs if doc["kind"] == "StatefulSet")
        self.assertNotIn("labels", claim["metadata"])
        self.assertEqual(stateful["spec"]["selector"]["matchLabels"], {
            "app.kubernetes.io/name": "defectdojo-notifications-mysql",
            "app.kubernetes.io/instance": POLICY["service_name"]})


class CleanupTests(unittest.TestCase):
    def setUp(self):
        self.assertTrue((CHART / "files/cleanup.py").is_file(), "cleanup implementation missing")
        bootstrap_spec = importlib.util.spec_from_file_location("managed_cleanup_bootstrap", CHART / "files/bootstrap.py")
        bootstrap = importlib.util.module_from_spec(bootstrap_spec)
        bootstrap_spec.loader.exec_module(bootstrap)
        spec = importlib.util.spec_from_file_location("notifications_cleanup", CHART / "files/cleanup.py")
        self.mod = importlib.util.module_from_spec(spec)
        with patch.dict(sys.modules, {"bootstrap": bootstrap}):
            spec.loader.exec_module(self.mod)
        self.clock, self.api = Clock(), FakeAPI()

    def cleanup(self, api=None, policy=None):
        return self.mod.Cleanup(api or self.api, policy or POLICY, sleep=self.clock.sleep, clock=self.clock.time)

    def deletes(self, api=None):
        return [call for call in (api or self.api).calls if call[0] == "DELETE"]

    def test_deletes_pvc_then_secret_with_uid_resource_version_preconditions(self):
        self.assertEqual(self.cleanup().run(), "purged")
        self.assertEqual(self.deletes(), [
            ("DELETE", "pvc", POLICY["pvc_name"], {"uid": "pvc-uid", "resourceVersion": "1"}),
            ("DELETE", "secret", POLICY["target_secret"], {"uid": "secret-uid", "resourceVersion": "1"})])
        pvc_confirmation = self.api.calls.index(("GET", "pvc", POLICY["pvc_name"]), self.api.calls.index(self.deletes()[0]))
        self.assertLess(pvc_confirmation, self.api.calls.index(self.deletes()[1]))

    def test_foreign_secret_preflight_prevents_deleting_even_an_owned_pvc(self):
        secret = owned_secret()
        secret['metadata']['annotations']['meta.helm.sh/release-name'] = 'another-release'
        api = FakeAPI(secrets=[secret])
        with self.assertRaisesRegex(self.mod.CleanupError, 'foreign_secret'):
            self.cleanup(api).run()
        self.assertEqual(self.deletes(api), [])

    def test_missing_state_is_idempotent_without_delete_requests(self):
        api = FakeAPI(pvcs=[None], secrets=[None])
        self.assertEqual(self.cleanup(api).run(), "purged")
        self.assertEqual(self.deletes(api), [])

    def test_existing_statefulset_blocks_every_delete(self):
        api = FakeAPI(statefulsets=[{"metadata": {"name": POLICY["service_name"]}}])
        with self.assertRaisesRegex(self.mod.CleanupError, "database_still_exists"):
            self.cleanup(api).run()
        self.assertEqual(self.deletes(api), [])

    def test_waits_for_pod_then_pvc_finalizer_disappearance_before_secret(self):
        api = FakeAPI(pods=[pod(), pod(), None], pvcs=[pvc(), pvc(), pvc(), None])
        self.assertEqual(self.cleanup(api).run(), "purged")
        self.assertGreater(self.clock.now, 0)
        self.assertEqual([call[1] for call in self.deletes(api)], ["pvc", "secret"])

    def test_wait_timeout_and_pvc_delete_error_preserve_secret(self):
        for api in (FakeAPI(pods=[pod()]), FakeAPI(pvcs=[pvc()])):
            with self.assertRaisesRegex(self.mod.CleanupError, "cleanup_timeout"):
                self.cleanup(api).run()
            self.assertFalse(any(call[1] == "secret" for call in self.deletes(api)))
            self.clock.now = 0
        self.api.fail_delete = "pvc"
        with self.assertRaises(self.mod.CleanupError):
            self.cleanup().run()
        self.assertFalse(any(call[1] == "secret" for call in self.deletes()))

    def test_foreign_labels_crossscope_or_missing_identity_block_deletion(self):
        for mutation in (lambda value: value["metadata"].update(namespace="other"),
                         lambda value: value["metadata"].update(name="other-pvc"),
                         lambda value: value["metadata"].update(uid=""),
                         lambda value: value["metadata"]["labels"].update({"app.kubernetes.io/instance": "other"}),
                         lambda value: value["metadata"]["labels"].update({"app.kubernetes.io/name": "application-data"})):
            value = pvc()
            mutation(value)
            api = FakeAPI(pvcs=[value])
            with self.assertRaises(self.mod.CleanupError):
                self.cleanup(api).run()
            self.assertEqual(self.deletes(api), [])

    def test_pvc_uid_changed_while_waiting_never_deletes_secret(self):
        api = FakeAPI(pvcs=[pvc(), pvc(uid="replacement")])
        with self.assertRaisesRegex(self.mod.CleanupError, "identity_changed"):
            self.cleanup(api).run()
        self.assertEqual([call[1] for call in self.deletes(api)], ["pvc"])

    def test_recreated_pod_while_waiting_fails_before_state_deletion(self):
        api = FakeAPI(pods=[pod(), pod(uid="replacement")])
        with self.assertRaisesRegex(self.mod.CleanupError, "identity_changed"):
            self.cleanup(api).run()
        self.assertEqual(self.deletes(api), [])

    def test_reappearing_database_or_pvc_preserves_recovery_secret(self):
        for api in (FakeAPI(statefulsets=[None, None, {"metadata": {"name": POLICY["service_name"]}}]),
                    FakeAPI(pvcs=[pvc(), None, pvc(uid="replacement")])):
            with self.assertRaises(self.mod.CleanupError):
                self.cleanup(api).run()
            self.assertEqual([call[1] for call in self.deletes(api)], ["pvc"])

    def test_foreign_secret_or_secret_uid_race_never_deletes_replacement(self):
        secret = owned_secret()
        secret["metadata"]["annotations"]["meta.helm.sh/release-name"] = "other-release"
        api = FakeAPI(pvcs=[None], secrets=[secret])
        with self.assertRaises(self.mod.CleanupError):
            self.cleanup(api).run()
        self.assertEqual(self.deletes(api), [])
        replacement = owned_secret()
        replacement["metadata"]["uid"] = "replacement"
        api = FakeAPI(pvcs=[None], secrets=[owned_secret(), owned_secret(), replacement])
        with self.assertRaisesRegex(self.mod.CleanupError, "identity_changed"):
            self.cleanup(api).run()
        self.assertEqual([call[1] for call in self.deletes(api)], ["secret"])

    def test_api_errors_do_not_mean_missing_and_never_expose_remote_messages(self):
        api = FakeAPI(pvcs=[RuntimeError("Forbidden api-token secret-password")])
        with self.assertRaises(self.mod.CleanupError) as caught:
            self.cleanup(api).run()
        self.assertNotIn("secret-password", repr(caught.exception))
        self.assertIsNone(caught.exception.__cause__)
        self.assertEqual(self.deletes(api), [])

    def test_arbitrary_policy_targets_are_rejected(self):
        for policy in (dict(POLICY, pvc_name="unrelated-application-pvc"),
                       dict(POLICY, target_secret="external-channel-secret")):
            with self.assertRaises(self.mod.CleanupError):
                self.cleanup(policy=policy).run()
        self.assertEqual(self.deletes(), [])

    def test_delete_transport_uses_exact_paths_and_json_deleteoptions(self):
        opener = Mock()
        body = io.BytesIO(b'{}')
        body.code = 200
        opener.open.return_value = body
        with patch.object(self.mod.bootstrap, "build_opener", return_value=opener):
            client = self.mod.CleanupAPI("https://kubernetes.example", POLICY, "bearer-token", None)
            client.delete("pvc", POLICY["pvc_name"], {"uid": "pvc-uid", "resourceVersion": "1"})
        request = opener.open.call_args.args[0]
        self.assertEqual(request.method, "DELETE")
        self.assertEqual(request.full_url, "https://kubernetes.example/api/v1/namespaces/example/persistentvolumeclaims/" + POLICY["pvc_name"])
        self.assertEqual(request.get_header("Content-type"), "application/json")
        self.assertEqual(json.loads(request.data), {"apiVersion": "v1", "kind": "DeleteOptions",
            "preconditions": {"uid": "pvc-uid", "resourceVersion": "1"}})
        with self.assertRaises(self.mod.CleanupError):
            client.delete("pod", POLICY["service_name"] + "-0", {"uid": "x", "resourceVersion": "1"})

    def test_transport_only_get404_means_absent_forbidden_and_conflict_fail(self):
        for code in (403, 409, 500):
            opener = Mock()
            body = io.BytesIO(b'private-api-token')
            opener.open.side_effect = HTTPError("https://kubernetes.example", code, "private-password", {}, body)
            with patch.object(self.mod.bootstrap, "build_opener", return_value=opener):
                client = self.mod.CleanupAPI("https://kubernetes.example", POLICY, "bearer-token", None)
                with self.assertRaises(self.mod.CleanupError) as caught:
                    client.get("pvc", POLICY["pvc_name"])
            self.assertTrue(body.closed)
            self.assertNotIn("private-password", repr(caught.exception))
        opener = Mock()
        body = io.BytesIO(b'not-found')
        body.code = 404
        opener.open.return_value = body
        with patch.object(self.mod.bootstrap, "build_opener", return_value=opener):
            client = self.mod.CleanupAPI("https://kubernetes.example", POLICY, "bearer-token", None)
            self.assertIsNone(client.get("pvc", POLICY["pvc_name"]))

    def test_cli_safe_errors_do_not_log_credentials(self):
        output = io.StringIO()
        with patch("sys.stdout", output), patch.object(self.mod, "read_file", side_effect=RuntimeError("secret-password")):
            self.assertEqual(self.mod.main([]), 1)
        self.assertEqual(json.loads(output.getvalue()), {"reason": "cleanup_aborted"})


if __name__ == "__main__":
    unittest.main()
