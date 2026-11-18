#!/usr/bin/env python3
"""Generate managed DB credentials once; deliberate TLS renewal preserves passwords.

Only the named Helm-owned Secret and retained PVC are read. A single JSON Patch
with UID/resourceVersion tests commits all changes. Never print remote content.
"""
import base64
import binascii
import hmac
import ipaddress
import json
import os
from pathlib import Path
import re
import secrets
import ssl
import sys
import tempfile
from urllib.error import HTTPError
from urllib.parse import urlsplit
from urllib.request import HTTPRedirectHandler, HTTPSHandler, Request, build_opener

KEYS = {"username", "password", "root-password", "ca.crt", "tls.crt", "tls.key"}
TLS_KEYS = ("ca.crt", "tls.crt", "tls.key")


class BootstrapError(Exception):
    """Static, safe reason code only."""


def name(value, maximum=253):
    return isinstance(value, str) and 1 <= len(value) <= maximum and all(
        re.fullmatch(r"[a-z0-9](?:[-a-z0-9]{0,61}[a-z0-9])?", part) for part in value.split("."))


def label(value):
    return name(value, 63) and "." not in value


class NoRedirect(HTTPRedirectHandler):
    def redirect_request(self, *args, **kwargs):
        return None


class KubeAPI:
    def __init__(self, base_url, namespace, bearer_token, ca_file):
        try:
            parsed = urlsplit(base_url)
            if (parsed.scheme != "https" or not parsed.hostname or parsed.path not in ("", "/")
                    or parsed.query or parsed.fragment or parsed.username is not None or parsed.password is not None
                    or re.search(r"[\s\\%\x00-\x1f\x7f]", base_url) or parsed.port == 0
                    or not label(namespace) or not isinstance(bearer_token, str)
                    or not re.fullmatch(r"[\x21-\x7e]{1,4096}", bearer_token)):
                raise ValueError()
            self.opener = build_opener(NoRedirect(), HTTPSHandler(context=ssl.create_default_context(cafile=ca_file)))
        except Exception:
            raise BootstrapError("invalid_kubernetes_config") from None
        self.base = base_url.rstrip("/")
        self.namespace = namespace
        self.authorization = "Bearer " + bearer_token
        self.calls = 0

    def request(self, method, resource, resource_name, operations=None):
        if not name(resource_name) or resource not in ("secrets", "persistentvolumeclaims"):
            raise BootstrapError("invalid_kubernetes_resource")
        if self.calls >= 20:
            raise BootstrapError("request_budget")
        self.calls += 1
        try:
            headers = {"Accept": "application/json", "Authorization": self.authorization}
            body = None
            if operations is not None:
                headers["Content-Type"] = "application/json-patch+json"
                body = json.dumps(operations).encode("utf-8")
            request = Request(self.base + f"/api/v1/namespaces/{self.namespace}/{resource}/{resource_name}",
                              data=body, headers=headers, method=method)
            try:
                response = self.opener.open(request, timeout=15)
            except HTTPError as error:
                response = error
            with response:
                raw = response.read(262145)
                if len(raw) > 262144:
                    raise BootstrapError("response_budget")
                if 300 <= response.code < 400:
                    raise BootstrapError("redirect_rejected")
                if response.code == 404 and method == "GET" and resource == "persistentvolumeclaims":
                    return None
                if response.code != 200:
                    raise BootstrapError("kubernetes_request_failed")
                data = json.loads(raw)
                if not isinstance(data, dict):
                    raise BootstrapError("invalid_kubernetes_response")
                return data
        except BootstrapError:
            raise
        except Exception:
            raise BootstrapError("kubernetes_request_failed") from None

    def get_secret(self, secret_name):
        return self.request("GET", "secrets", secret_name)

    def patch_secret(self, secret_name, operations):
        self.request("PATCH", "secrets", secret_name, operations)

    def pvc_exists(self, pvc_name):
        result = self.request("GET", "persistentvolumeclaims", pvc_name)
        if result is None:
            return False
        metadata = result.get("metadata")
        if (not isinstance(metadata, dict) or metadata.get("name") != pvc_name
                or metadata.get("namespace") != self.namespace or not metadata.get("uid")):
            raise BootstrapError("invalid_pvc_response")
        return True


class Bootstrap:
    def __init__(self, kube, config, tls_dir="/work/tls", random_token=None):
        self.config = self.validate(config)
        self.kube = kube
        self.tls_dir = Path(tls_dir)
        self.random_token = random_token if random_token is not None else lambda: secrets.token_urlsafe(36)

    @staticmethod
    def validate(config):
        required = {"namespace", "release_name", "target_secret", "service_name", "pvc_name", "username"}
        if not isinstance(config, dict) or set(config) != required:
            raise BootstrapError("invalid_policy")
        if (not label(config["namespace"]) or not name(config["release_name"], 53)
                or not name(config["target_secret"]) or not label(config["service_name"])
                or not name(config["pvc_name"]) or config["username"] != "notifier"):
            raise BootstrapError("invalid_policy")
        return dict(config)

    @staticmethod
    def call(function, *args):
        try:
            return function(*args)
        except BootstrapError:
            raise
        except Exception:
            raise BootstrapError("kubernetes_request_failed") from None

    def secret(self):
        secret = self.call(self.kube.get_secret, self.config["target_secret"])
        if not isinstance(secret, dict) or secret.get("type") != "Opaque" or "stringData" in secret:
            raise BootstrapError("invalid_target_secret")
        metadata = secret.get("metadata")
        if (not isinstance(metadata, dict) or not isinstance(metadata.get("labels"), dict)
                or not isinstance(metadata.get("annotations"), dict)):
            raise BootstrapError("invalid_secret_ownership")
        expected = ((metadata, "name", self.config["target_secret"]),
                    (metadata, "namespace", self.config["namespace"]),
                    (metadata["labels"], "app.kubernetes.io/managed-by", "Helm"),
                    (metadata["labels"], "app.kubernetes.io/instance", self.config["release_name"]),
                    (metadata["annotations"], "meta.helm.sh/release-name", self.config["release_name"]),
                    (metadata["annotations"], "meta.helm.sh/release-namespace", self.config["namespace"]))
        if any(source.get(key) != value for source, key, value in expected):
            raise BootstrapError("invalid_secret_ownership")
        for key in ("uid", "resourceVersion"):
            if not isinstance(metadata.get(key), str) or not re.fullmatch(r"[\x21-\x7e]{1,512}", metadata[key]):
                raise BootstrapError("invalid_secret_identity")
        data = secret.get("data", {})
        if not isinstance(data, dict) or any(not isinstance(key, str) or not isinstance(value, str) for key, value in data.items()):
            raise BootstrapError("invalid_secret_data")
        return secret

    def decoded(self, data):
        if set(data) != KEYS:
            raise BootstrapError("partial_secret")
        try:
            result = {key: base64.b64decode(value, validate=True).decode("utf-8") for key, value in data.items()}
        except (ValueError, binascii.Error, UnicodeError):
            raise BootstrapError("invalid_secret_data") from None
        if result["username"] != self.config["username"]:
            raise BootstrapError("invalid_username")
        for key in ("password", "root-password"):
            if not re.fullmatch(r"[A-Za-z0-9_-]{32,128}", result[key]):
                raise BootstrapError("invalid_password")
        if result["password"] == result["root-password"]:
            raise BootstrapError("invalid_password")
        for key in TLS_KEYS:
            if not 1 <= len(result[key]) <= 16384:
                raise BootstrapError("invalid_tls")
        return result

    def validate_tls(self, values, check_expiry=True):
        """Verify private key, private CA chain, expiration and Service hostname.

        MemoryBIO performs a TLS handshake without opening a network socket. The
        explicit renewal path still validates old PEM/key structure, but permits
        an expired old certificate so replacement does not reset DB passwords.
        """
        try:
            with tempfile.TemporaryDirectory(dir=self.tls_dir) as directory:
                for key in TLS_KEYS:
                    path = Path(directory) / key
                    path.write_text(values[key], encoding="utf-8")
                    path.chmod(0o600)
                server_context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
                server_context.minimum_version = ssl.TLSVersion.TLSv1_2
                server_context.load_cert_chain(str(Path(directory) / "tls.crt"), str(Path(directory) / "tls.key"))
                client_context = ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
                client_context.minimum_version = ssl.TLSVersion.TLSv1_2
                client_context.load_verify_locations(cadata=values["ca.crt"])
                if not check_expiry:
                    return
                client_in, client_out, server_in, server_out = (ssl.MemoryBIO() for _ in range(4))
                host = self.config["service_name"] + "." + self.config["namespace"] + ".svc"
                client = client_context.wrap_bio(client_in, client_out, server_hostname=host)
                server = server_context.wrap_bio(server_in, server_out, server_side=True)
                client_done = server_done = False
                for _ in range(20):
                    for peer, done in ((client, client_done), (server, server_done)):
                        if done:
                            continue
                        try:
                            peer.do_handshake()
                            if peer is client:
                                client_done = True
                            else:
                                server_done = True
                        except ssl.SSLWantReadError:
                            pass
                    if client_out.pending:
                        server_in.write(client_out.read())
                    if server_out.pending:
                        client_in.write(server_out.read())
                    if client_done and server_done:
                        return
                raise ValueError()
        except Exception:
            raise BootstrapError("invalid_tls") from None

    def candidate(self):
        try:
            result = {key: (self.tls_dir / key).read_text(encoding="utf-8") for key in TLS_KEYS}
        except Exception:
            raise BootstrapError("invalid_tls") from None
        self.validate_tls(result)
        return result

    def patch(self, secret, data, tls_only=False):
        metadata = secret["metadata"]
        operations = [{"op": "test", "path": "/metadata/uid", "value": metadata["uid"]},
                      {"op": "test", "path": "/metadata/resourceVersion", "value": metadata["resourceVersion"]}]
        if tls_only:
            operations.extend({"op": "add", "path": "/data/" + key, "value": data[key]} for key in TLS_KEYS)
        else:
            operations.append({"op": "add", "path": "/data", "value": data})
        self.call(self.kube.patch_secret, self.config["target_secret"], operations)
        confirmed = self.secret()
        actual = confirmed.get("data", {})
        if confirmed["metadata"]["uid"] != metadata["uid"] or set(actual) != set(data) or any(
                not hmac.compare_digest(actual.get(key, ""), value) for key, value in data.items()):
            raise BootstrapError("secret_confirmation_failed")

    def run(self, mode="bootstrap"):
        if mode not in ("bootstrap", "renew-tls"):
            raise BootstrapError("invalid_command")
        secret = self.secret()
        data = secret.get("data", {})
        if not data:
            if mode == "renew-tls":
                raise BootstrapError("renewal_requires_complete_secret")
            if self.call(self.kube.pvc_exists, self.config["pvc_name"]) is not False:
                raise BootstrapError("credentials_recovery_required")
            values = self.candidate()
            values.update(username=self.config["username"], password=self.random_token())
            values["root-password"] = self.random_token()
            encoded = {key: base64.b64encode(value.encode("utf-8")).decode("ascii") for key, value in values.items()}
            self.decoded(encoded)
            self.patch(secret, encoded)
            return "created"
        values = self.decoded(data)
        self.validate_tls(values, check_expiry=mode != "renew-tls")
        if mode == "bootstrap":
            return "reused"
        candidate = self.candidate()
        renewed = dict(data)
        renewed.update({key: base64.b64encode(candidate[key].encode("utf-8")).decode("ascii") for key in TLS_KEYS})
        self.patch(secret, renewed, tls_only=True)
        return "renewed"


def read_file(path, maximum):
    with open(path, encoding="utf-8", newline="") as source:
        value = source.read(maximum + 1)
    if len(value) > maximum:
        raise BootstrapError("input_budget")
    return value


def main(argv=None):
    argv = sys.argv[1:] if argv is None else argv
    try:
        if argv not in ([], ["renew-tls"]):
            raise BootstrapError("invalid_command")
        policy = json.loads(read_file(os.environ.get("BOOTSTRAP_POLICY_FILE", "/config/policy.json"), 65536))
        Bootstrap.validate(policy)
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
        kube = KubeAPI("https://" + host + ":" + port, policy["namespace"], bearer, mount + "ca.crt")
        result = Bootstrap(kube, policy).run(mode="renew-tls" if argv else "bootstrap")
        print(json.dumps({"reason": result}), flush=True)
        return 0
    except Exception as error:
        reason = str(error) if isinstance(error, BootstrapError) else "bootstrap_aborted"
        if not re.fullmatch(r"[a-z][a-z0-9_]{0,63}", reason):
            reason = "bootstrap_aborted"
        print(json.dumps({"reason": reason}), flush=True)
        return 1


if __name__ == "__main__":
    sys.exit(main())
