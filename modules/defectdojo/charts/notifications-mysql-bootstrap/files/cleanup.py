#!/usr/bin/env python3
"""Purge only the managed notification PVC and generated Secret on uninstall.

Workloads must be gone first. DeleteOptions UID/resourceVersion preconditions
and post-delete absence checks protect replacement objects and credentials.
"""
import ipaddress
import json
import os
import re
import sys
import time
from urllib.error import HTTPError
from urllib.request import Request

import bootstrap
from bootstrap import Bootstrap, KubeAPI, name, read_file


class CleanupError(Exception):
    """Static reason codes only; never remote responses, names or secret values."""


def policy(config):
    try:
        config = Bootstrap.validate(config)
        service = config["service_name"]
        if (config["pvc_name"] != "data-" + service + "-0"
                or config["target_secret"] != service + "-credentials"):
            raise ValueError()
        return config
    except Exception:
        raise CleanupError("invalid_cleanup_policy") from None


def identity(value):
    return isinstance(value, str) and re.fullmatch(r"[\x21-\x7e]{1,512}", value) is not None


class CleanupAPI(KubeAPI):
    def __init__(self, base_url, config, bearer_token, ca_file):
        self.config = policy(config)
        try:
            super().__init__(base_url, self.config["namespace"], bearer_token, ca_file)
        except Exception:
            raise CleanupError("invalid_kubernetes_config") from None
        self.resources = {
            "statefulset": ("/apis/apps/v1", "statefulsets", self.config["service_name"]),
            "pod": ("/api/v1", "pods", self.config["service_name"] + "-0"),
            "pvc": ("/api/v1", "persistentvolumeclaims", self.config["pvc_name"]),
            "secret": ("/api/v1", "secrets", self.config["target_secret"]),
        }

    def resource_request(self, method, kind, resource_name, preconditions=None):
        if kind not in self.resources or resource_name != self.resources[kind][2]:
            raise CleanupError("invalid_cleanup_resource")
        if method not in ("GET", "DELETE") or method == "DELETE" and kind not in ("pvc", "secret"):
            raise CleanupError("invalid_cleanup_operation")
        if self.calls >= 250:
            raise CleanupError("request_budget")
        self.calls += 1
        headers = {"Accept": "application/json", "Authorization": self.authorization}
        body = None
        if method == "DELETE":
            if (not isinstance(preconditions, dict) or set(preconditions) != {"uid", "resourceVersion"}
                    or not all(identity(value) for value in preconditions.values())):
                raise CleanupError("invalid_delete_preconditions")
            headers["Content-Type"] = "application/json"
            body = json.dumps({"apiVersion": "v1", "kind": "DeleteOptions", "preconditions": preconditions}).encode("utf-8")
        prefix, resource, _ = self.resources[kind]
        request = Request(self.base + prefix + f"/namespaces/{self.namespace}/{resource}/{resource_name}",
                          method=method, headers=headers, data=body)
        try:
            try:
                response = self.opener.open(request, timeout=15)
            except HTTPError as error:
                response = error
            with response:
                raw = response.read(262145)
                if len(raw) > 262144:
                    raise CleanupError("response_budget")
                if 300 <= response.code < 400:
                    raise CleanupError("redirect_rejected")
                if response.code == 404:
                    return None
                if method == "DELETE":
                    if response.code not in (200, 202):
                        raise CleanupError("cleanup_request_failed")
                    return None
                if response.code != 200:
                    raise CleanupError("cleanup_request_failed")
                result = json.loads(raw)
                if not isinstance(result, dict):
                    raise CleanupError("invalid_cleanup_response")
                return result
        except CleanupError:
            raise
        except Exception:
            raise CleanupError("cleanup_request_failed") from None

    def get(self, kind, resource_name):
        return self.resource_request("GET", kind, resource_name)

    def delete(self, kind, resource_name, preconditions):
        self.resource_request("DELETE", kind, resource_name, preconditions)


class Cleanup:
    def __init__(self, api, config, sleep=time.sleep, clock=time.monotonic):
        self.config = policy(config)
        self.api, self.sleep, self.clock = api, sleep, clock
        self.started = clock()
        self.calls = 0

    def budget(self):
        if self.clock() - self.started >= 540:
            raise CleanupError("cleanup_timeout")
        if self.calls >= 250:
            raise CleanupError("request_budget")

    def call(self, method, *args):
        self.budget()
        self.calls += 1
        try:
            result = method(*args)
        except CleanupError:
            raise
        except Exception:
            raise CleanupError("cleanup_request_failed") from None
        self.budget()
        return result

    def pause(self):
        self.budget()
        self.sleep(min(3, 540 - (self.clock() - self.started)))

    def metadata(self, value, kind, resource_name):
        if not isinstance(value, dict) or not isinstance(value.get("metadata"), dict):
            raise CleanupError("invalid_cleanup_object")
        metadata = value["metadata"]
        if (metadata.get("name") != resource_name or metadata.get("namespace") != self.config["namespace"]
                or not identity(metadata.get("uid")) or not identity(metadata.get("resourceVersion"))):
            raise CleanupError("invalid_cleanup_identity")
        if kind == "pvc":
            labels = metadata.get("labels")
            if (not isinstance(labels, dict)
                    or labels.get("app.kubernetes.io/name") != "defectdojo-notifications-mysql"
                    or labels.get("app.kubernetes.io/instance") != self.config["service_name"]):
                raise CleanupError("foreign_pvc")
        if kind == "secret":
            labels, annotations = metadata.get("labels"), metadata.get("annotations")
            if not isinstance(labels, dict) or not isinstance(annotations, dict) or value.get("type") != "Opaque":
                raise CleanupError("foreign_secret")
            if (labels.get("app.kubernetes.io/managed-by") != "Helm"
                    or labels.get("app.kubernetes.io/instance") != self.config["release_name"]
                    or annotations.get("meta.helm.sh/release-name") != self.config["release_name"]
                    or annotations.get("meta.helm.sh/release-namespace") != self.config["namespace"]):
                raise CleanupError("foreign_secret")
        return metadata

    def database_absent(self):
        if self.call(self.api.get, "statefulset", self.config["service_name"]) is not None:
            raise CleanupError("database_still_exists")

    def wait_pod(self):
        pod_name = self.config["service_name"] + "-0"
        uid = None
        while True:
            value = self.call(self.api.get, "pod", pod_name)
            if value is None:
                return
            metadata = self.metadata(value, "pod", pod_name)
            if uid is not None and metadata["uid"] != uid:
                raise CleanupError("identity_changed")
            uid = metadata["uid"]
            self.pause()

    def remove(self, kind, resource_name):
        value = self.call(self.api.get, kind, resource_name)
        if value is None:
            return
        metadata = self.metadata(value, kind, resource_name)
        if kind == "secret" and (self.secret_preflight is None or any(
                metadata[key] != self.secret_preflight[key] for key in ("uid", "resourceVersion"))):
            raise CleanupError("identity_changed")
        preconditions = {key: metadata[key] for key in ("uid", "resourceVersion")}
        if kind == "secret":
            # Protect recovery credentials if another actor recreated a workload
            # or PVC while the original PVC's protection finalizer was draining.
            self.database_absent()
            if self.call(self.api.get, "pod", self.config["service_name"] + "-0") is not None:
                raise CleanupError("database_pod_reappeared")
            if self.call(self.api.get, "pvc", self.config["pvc_name"]) is not None:
                raise CleanupError("database_state_reappeared")
        self.call(self.api.delete, kind, resource_name, preconditions)
        while True:
            remaining = self.call(self.api.get, kind, resource_name)
            if remaining is None:
                return
            current = self.metadata(remaining, kind, resource_name)
            if current["uid"] != metadata["uid"]:
                raise CleanupError("identity_changed")
            self.pause()

    def run(self):
        self.database_absent()
        self.wait_pod()
        # Recheck after a potentially long Pod wait before touching state.
        self.database_absent()
        # Validate recovery-credential ownership before the first destructive
        # operation, then compare the same UID/version again before its DELETE.
        secret = self.call(self.api.get, "secret", self.config["target_secret"])
        self.secret_preflight = (self.metadata(secret, "secret", self.config["target_secret"])
                                 if secret is not None else None)
        self.remove("pvc", self.config["pvc_name"])
        # Never delete recovery credentials until the original PVC is absent.
        self.remove("secret", self.config["target_secret"])
        return "purged"


def main(argv=None):
    argv = sys.argv[1:] if argv is None else argv
    try:
        if argv:
            raise CleanupError("invalid_command")
        config = policy(json.loads(read_file(os.environ.get("BOOTSTRAP_POLICY_FILE", "/config/policy.json"), 65536)))
        mount = "/var/run/secrets/kubernetes.io/serviceaccount/"
        bearer = read_file(mount + "token", 4096).strip()
        host = os.environ.get("KUBERNETES_SERVICE_HOST", "")
        port = os.environ.get("KUBERNETES_SERVICE_PORT_HTTPS", "443")
        if ":" in host:
            host = "[" + str(ipaddress.IPv6Address(host)) + "]"
        elif not name(host):
            raise CleanupError("invalid_kubernetes_host")
        if not re.fullmatch(r"[0-9]{1,5}", port) or not 1 <= int(port) <= 65535:
            raise CleanupError("invalid_kubernetes_port")
        api = CleanupAPI("https://" + host + ":" + port, config, bearer, mount + "ca.crt")
        result = Cleanup(api, config).run()
        print(json.dumps({"reason": result}), flush=True)
        return 0
    except Exception as error:
        reason = str(error) if isinstance(error, CleanupError) else "cleanup_aborted"
        if not re.fullmatch(r"[a-z][a-z0-9_]{0,63}", reason):
            reason = "cleanup_aborted"
        print(json.dumps({"reason": reason}), flush=True)
        return 1


if __name__ == "__main__":
    sys.exit(main())
