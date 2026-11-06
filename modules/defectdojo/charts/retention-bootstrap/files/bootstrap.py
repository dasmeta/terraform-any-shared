#!/usr/bin/env python3
"""Create or reuse a Helm-owned API-token Secret without rotating shared tokens."""

import base64
import binascii
import hmac
import ipaddress
import json
import os
import re
import ssl
import sys
import time
from datetime import datetime
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode, urlsplit
from urllib.request import HTTPRedirectHandler, HTTPSHandler, Request, build_opener


class BootstrapError(Exception):
    """A static reason code, never a remote response or credential."""


def origin(value, https_only=False):
    if not isinstance(value, str):
        raise BootstrapError("invalid_api_origin")
    try:
        parts = urlsplit(value)
        if (parts.scheme not in (("https",) if https_only else ("https", "http"))
                or not parts.hostname or parts.username is not None or parts.password is not None
                or parts.path not in ("", "/") or parts.query or parts.fragment
                or parts.port == 0 or re.search(r"[\s\\%\x00-\x1f\x7f]", value)):
            raise ValueError()
    except (TypeError, ValueError):
        raise BootstrapError("invalid_api_origin") from None
    return value.rstrip("/")


def name(value, maximum=253):
    return (isinstance(value, str) and 1 <= len(value) <= maximum
            and all(re.fullmatch(r"[a-z0-9](?:[-a-z0-9]{0,61}[a-z0-9])?", part)
                    for part in value.split(".")))


def token(value):
    return (isinstance(value, str) and 1 <= len(value) <= 4096
            and re.fullmatch(r"[\x21-\x7e]+", value) is not None)


class NoRedirect(HTTPRedirectHandler):
    def redirect_request(self, *args, **kwargs):
        return None


class HTTP:
    def __init__(self, base_url, ca_file=None, https_only=False):
        self.base = origin(base_url, https_only)
        context = ssl.create_default_context(cafile=ca_file)
        self.opener = build_opener(NoRedirect(), HTTPSHandler(context=context))
        self.calls = 0

    def request(self, method, path, payload=None, authorization=None, patch=False):
        if self.calls >= 500:
            raise BootstrapError("request_budget")
        self.calls += 1
        headers = {"Accept": "application/json"}
        if authorization:
            headers["Authorization"] = authorization
        if payload is not None:
            headers["Content-Type"] = "application/json-patch+json" if patch else "application/json"
        request = Request(self.base + path, method=method, headers=headers,
                          data=json.dumps(payload).encode("utf-8") if payload is not None else None)
        try:
            with self.opener.open(request, timeout=15) as response:
                body = response.read(2 * 1024 * 1024 + 1)
                if len(body) > 2 * 1024 * 1024:
                    raise BootstrapError("response_budget")
                return response.status, body
        except HTTPError as error:
            status = error.code
            error.close()
            if 300 <= status < 400:
                raise BootstrapError("redirect_rejected") from None
            return status, None
        except (URLError, OSError, ValueError):
            raise BootstrapError("connection_failed") from None

    @staticmethod
    def decode(body):
        try:
            return json.loads(body)
        except (TypeError, ValueError, RecursionError):
            raise BootstrapError("invalid_json_response") from None


class DojoAPI(HTTP):
    def ready(self):
        try:
            status, _ = self.request("GET", "/api/v2/")
        except BootstrapError as error:
            if str(error) == "connection_failed":
                return False
            raise
        if status in (200, 401, 403):
            return True
        if status == 404 or 500 <= status <= 599:
            return False
        raise BootstrapError("readiness_status")

    def login(self, username, password):
        status, body = self.request("POST", "/api/v2/api-token-auth/",
                                    {"username": username, "password": password})
        if status != 200:
            raise BootstrapError("authentication_failed")
        result = self.decode(body)
        if not isinstance(result, dict) or not token(result.get("token")):
            raise BootstrapError("invalid_token_response")
        return result["token"]

    def validate_token(self, value):
        if not token(value):
            raise BootstrapError("invalid_token")
        status, body = self.request("GET", "/api/v2/tests/?limit=1", authorization="Token " + value)
        if status in (401, 403):
            return False
        if status != 200:
            raise BootstrapError("token_validation_status")
        result = self.decode(body)
        if (not isinstance(result, dict) or type(result.get("count")) is not int
                or result["count"] < 0 or not isinstance(result.get("results"), list)
                or len(result["results"]) > 1 or result["count"] < len(result["results"])
                or (result["count"] > 0 and not result["results"])
                or any(not isinstance(row, dict) for row in result["results"])):
            raise BootstrapError("invalid_token_validation_response")
        return True


class KubeAPI(HTTP):
    def __init__(self, base_url, namespace, bearer_token, ca_file):
        if not name(namespace, 63) or "." in namespace or not token(bearer_token):
            raise BootstrapError("invalid_kubernetes_config")
        super().__init__(base_url, ca_file=ca_file, https_only=True)
        self.namespace, self.authorization = namespace, "Bearer " + bearer_token

    def get_secret(self, secret_name):
        if not name(secret_name):
            raise BootstrapError("invalid_secret_name")
        status, body = self.request("GET", f"/api/v1/namespaces/{self.namespace}/secrets/{secret_name}",
                                    authorization=self.authorization)
        if status != 200:
            raise BootstrapError("secret_get_failed")
        return self.decode(body)

    def patch_secret(self, secret_name, operations):
        if not name(secret_name):
            raise BootstrapError("invalid_secret_name")
        status, _ = self.request("PATCH", f"/api/v1/namespaces/{self.namespace}/secrets/{secret_name}",
                                 operations, authorization=self.authorization, patch=True)
        if status != 200:
            raise BootstrapError("secret_patch_failed")

    def list_initializers(self, application_release):
        if not name(application_release, 53):
            raise BootstrapError("invalid_application_release")
        query = urlencode({"labelSelector": "app.kubernetes.io/instance=" + application_release
                           + ",defectdojo.org/component=initializer", "limit": 100})
        status, body = self.request("GET", f"/apis/batch/v1/namespaces/{self.namespace}/jobs?{query}",
                                    authorization=self.authorization)
        if status != 200:
            raise BootstrapError("initializer_list_failed")
        result = self.decode(body)
        if (not isinstance(result, dict) or not isinstance(result.get("items"), list)
                or len(result["items"]) > 100 or not isinstance(result.get("metadata", {}), dict)
                or result.get("metadata", {}).get("continue")):
            raise BootstrapError("initializer_list_budget_or_shape")
        return result["items"]


class Bootstrap:
    def __init__(self, kube, dojo, config, username, password, sleep=time.sleep, clock=time.monotonic):
        self.config = self.validate(config)
        if (not isinstance(username, str) or not username or len(username) > 1024
                or not isinstance(password, str) or not password or len(password) > 16384):
            raise BootstrapError("invalid_credentials")
        self.kube, self.dojo, self.username, self.password = kube, dojo, username, password
        self.sleep, self.clock, self.started, self.calls = sleep, clock, clock(), 0

    @staticmethod
    def validate(config):
        fields = {"namespace", "target_secret", "target_key", "release_name", "application_release", "api_url"}
        if not isinstance(config, dict) or set(config) - fields or fields - {"api_url"} - set(config):
            raise BootstrapError("invalid_policy")
        for key, length in (("namespace", 63), ("target_secret", 253), ("release_name", 53), ("application_release", 53)):
            if not name(config[key], length) or (key == "namespace" and "." in config[key]):
                raise BootstrapError("invalid_" + key)
        if (not isinstance(config["target_key"], str) or not 1 <= len(config["target_key"]) <= 253
                or not re.fullmatch(r"[-._a-zA-Z0-9]+", config["target_key"])):
            raise BootstrapError("invalid_target_key")
        if "api_url" in config:
            origin(config["api_url"])
        return dict(config)

    def budget(self):
        if self.clock() - self.started >= 540:
            raise BootstrapError("runtime_budget")
        if self.calls >= 500:
            raise BootstrapError("request_budget")

    def call(self, method, *args):
        self.budget()
        self.calls += 1
        result = method(*args)
        if self.clock() - self.started >= 540:
            raise BootstrapError("runtime_budget")
        return result

    def pause(self):
        self.budget()
        self.sleep(min(3, 540 - (self.clock() - self.started)))

    def secret(self):
        result = self.call(self.kube.get_secret, self.config["target_secret"])
        if not isinstance(result, dict) or result.get("type") != "Opaque":
            raise BootstrapError("invalid_target_secret")
        meta = result.get("metadata")
        if not isinstance(meta, dict) or not isinstance(meta.get("labels"), dict) or not isinstance(meta.get("annotations"), dict):
            raise BootstrapError("invalid_secret_ownership")
        expected = ((meta, "name", self.config["target_secret"]), (meta, "namespace", self.config["namespace"]),
                    (meta["labels"], "app.kubernetes.io/managed-by", "Helm"),
                    (meta["labels"], "app.kubernetes.io/instance", self.config["release_name"]),
                    (meta["annotations"], "meta.helm.sh/release-name", self.config["release_name"]),
                    (meta["annotations"], "meta.helm.sh/release-namespace", self.config["namespace"]))
        if any(source.get(key) != value for source, key, value in expected):
            raise BootstrapError("invalid_secret_ownership")
        for key in ("uid", "resourceVersion"):
            if not isinstance(meta.get(key), str) or not re.fullmatch(r"[\x21-\x7e]{1,512}", meta[key]):
                raise BootstrapError("invalid_secret_identity")
        data = result.get("data", {})
        if not isinstance(data, dict) or any(not isinstance(k, str) or not isinstance(v, str) for k, v in data.items()):
            raise BootstrapError("invalid_secret_data")
        return result

    def initialized(self):
        jobs = self.call(self.kube.list_initializers, self.config["application_release"])
        if not isinstance(jobs, list) or len(jobs) > 100:
            raise BootstrapError("initializer_list_budget_or_shape")
        states = []
        for job in jobs:
            try:
                metadata = job["metadata"]
                if (metadata["namespace"] != self.config["namespace"]
                        or metadata["labels"]["app.kubernetes.io/instance"] != self.config["application_release"]
                        or metadata["labels"]["defectdojo.org/component"] != "initializer"):
                    raise ValueError()
                created = datetime.fromisoformat(metadata["creationTimestamp"].replace("Z", "+00:00"))
                if created.utcoffset() is None:
                    raise ValueError()
                conditions = job.get("status", {}).get("conditions", [])
                if not isinstance(conditions, list):
                    raise ValueError()
                state = {}
                for condition in conditions:
                    kind, status = condition["type"], condition["status"]
                    if not isinstance(kind, str) or kind in state or status not in ("True", "False", "Unknown"):
                        raise ValueError()
                    state[kind] = status
                states.append((created, state))
            except (KeyError, TypeError, ValueError, AttributeError):
                raise BootstrapError("invalid_initializer_response") from None
        if not states:
            return True
        latest = max(created for created, _ in states)
        newest = [state for created, state in states if created == latest]
        if any(state.get("Failed") == "True" for state in newest):
            raise BootstrapError("initializer_failed")
        return all(state.get("Complete") == "True" for state in newest)

    def run(self):
        secret = self.secret()
        while not self.initialized():
            self.pause()
        while not self.call(self.dojo.ready):
            self.pause()
        key = self.config["target_key"]
        stored = secret.get("data", {}).get(key, "")
        if stored:
            try:
                value = base64.b64decode(stored, validate=True).decode("ascii")
            except (ValueError, binascii.Error, UnicodeError):
                raise BootstrapError("invalid_stored_token") from None
            if not token(value) or self.call(self.dojo.validate_token, value) is not True:
                raise BootstrapError("stored_token_validation_failed")
            return "reused"
        value = self.call(self.dojo.login, self.username, self.password)
        if not token(value) or self.call(self.dojo.validate_token, value) is not True:
            raise BootstrapError("new_token_validation_failed")
        encoded = base64.b64encode(value.encode("ascii")).decode("ascii")
        operations = [{"op": "test", "path": "/metadata/uid", "value": secret["metadata"]["uid"]},
                      {"op": "test", "path": "/metadata/resourceVersion", "value": secret["metadata"]["resourceVersion"]}]
        operations.append({"op": "add", "path": "/data/" + key, "value": encoded} if "data" in secret
                          else {"op": "add", "path": "/data", "value": {key: encoded}})
        self.call(self.kube.patch_secret, self.config["target_secret"], operations)
        confirmed = self.secret()
        actual = confirmed.get("data", {}).get(key)
        if (confirmed["metadata"]["uid"] != secret["metadata"]["uid"]
                or not isinstance(actual, str) or not hmac.compare_digest(actual, encoded)):
            raise BootstrapError("secret_confirmation_failed")
        return "created"


def read_file(path, maximum):
    with open(path, encoding="utf-8", newline="") as source:
        value = source.read(maximum + 1)
    if len(value) > maximum:
        raise BootstrapError("input_budget")
    return value


def main():
    try:
        config = json.loads(read_file(os.environ.get("BOOTSTRAP_POLICY_FILE", "/config/policy.json"), 65536))
        Bootstrap.validate(config)
        if "api_url" not in config:
            raise BootstrapError("invalid_api_origin")
        username = read_file("/credentials/username", 1024)
        password = read_file("/credentials/password", 16384)
        mount = "/var/run/secrets/kubernetes.io/serviceaccount/"
        bearer = read_file(mount + "token", 4096).strip()
        host = os.environ.get("KUBERNETES_SERVICE_HOST", "")
        port = os.environ.get("KUBERNETES_SERVICE_PORT_HTTPS", "443")
        if ":" in host:
            host = "[" + str(ipaddress.IPv6Address(host)) + "]"
        elif not name(host):
            raise BootstrapError("invalid_kubernetes_host")
        if not re.fullmatch(r"[0-9]{1,5}", port) or not 1 <= int(port) <= 65535:
            raise BootstrapError("invalid_kubernetes_port")
        kube = KubeAPI("https://" + host + ":" + port, config["namespace"], bearer, mount + "ca.crt")
        result = Bootstrap(kube, DojoAPI(config["api_url"]), config, username, password).run()
        print(json.dumps({"reason": result}), flush=True)
        return 0
    except (BootstrapError, OSError, ValueError, TypeError) as error:
        reason = str(error) if isinstance(error, BootstrapError) else "bootstrap_aborted"
        if not re.fullmatch(r"[a-z][a-z0-9_]{0,63}", reason):
            reason = "bootstrap_aborted"
        print(json.dumps({"reason": reason}), flush=True)
        return 1


if __name__ == "__main__":
    sys.exit(main())
