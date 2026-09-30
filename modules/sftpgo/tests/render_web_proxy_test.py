"""Render the pinned Helm chart using real Terraform locals, without a cluster."""

import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile


def run(command, **kwargs):
    return subprocess.run(command, check=True, capture_output=True, text=True, **kwargs).stdout


module = Path(__file__).resolve().parents[1]
chart = str(Path(sys.argv[1]).resolve())

with tempfile.TemporaryDirectory(prefix="sftpgo-proxy-test-") as directory:
    directory = Path(directory)
    # Evaluate the real value builder in isolation from state and providers.
    for filename in ("variables.tf", "locals.tf"):
        shutil.copy(module / filename, directory / filename)
    variables = {
        "admin": {"password": "test-admin-password"},
        "s3_storage": {
            "bucket": "test-sftpgo", "region": "eu-central-1",
            "access_key": "test-key", "access_secret": "test-secret",
        },
        "bootstrap_users": [{"username": "test-user", "password": "test-password"}],
        "web_session": {
            "signing_passphrase": "test-stable-signing-passphrase",
            "cookie_lifetime": 600, "token_validation": 0,
        },
        "web_proxy": {"proxy_allowed": ["10.0.1.0/24", "10.0.2.0/24"]},
    }
    (directory / "test.auto.tfvars.json").write_text(json.dumps(variables))
    encoded = run(
        ["terraform", "console", "-no-color"], cwd=directory,
        input="nonsensitive(jsonencode(local.chart_values))\n",
    )
    values = json.loads(json.loads(encoded))
    values_file = directory / "values.json"
    values_file.write_text(json.dumps(values))
    manifest = run(["helm", "template", "test-sftpgo", chart, "-f", str(values_file)])
    resources = json.loads(run(
        ["ruby", "-ryaml", "-rjson", "-e",
         "puts JSON.generate(YAML.load_stream(STDIN.read).compact)"], input=manifest,
    ))
    configmap = next(r for r in resources if r["kind"] == "ConfigMap")
    config = json.loads(configmap["data"]["sftpgo.json"])
    httpd = config["httpd"]
    binding = httpd["bindings"][0]
    assert binding["proxy_allowed"] == variables["web_proxy"]["proxy_allowed"]
    assert binding["client_ip_proxy_header"] == "X-Forwarded-For"
    assert binding["client_ip_header_depth"] == 0
    assert binding["port"] == 8080
    assert all(binding[key] for key in ("enable_web_admin", "enable_web_client", "enable_rest_api"))
    assert all(httpd[key] == value for key, value in variables["web_session"].items())
    assert config["common"]["setstat_mode"] == 2
    assert config["data_provider"]["create_default_admin"] is True
    deployment = next(r for r in resources if r["kind"] == "Deployment")
    containers = deployment["spec"]["template"]["spec"]["containers"]
    application = next(c for c in containers if c["name"] == "sftpgo")
    env = {e["name"]: e.get("value") for e in application["env"]}
    assert env["SFTPGO_HTTPD__BINDINGS__0__PORT"] == "8080"
    assert any(c["name"] == "user-bootstrap" for c in containers)
    assert any(v.get("configMap", {}).get("name") == configmap["metadata"]["name"]
               for v in deployment["spec"]["template"]["spec"]["volumes"])

    # Render the maintenance/Secret path as real chart manifests, including PDB selectors.
    variables["bootstrap_users"] = []
    variables["web_session"] = {
        "signing_passphrase_secret_ref": {"name": "test-session", "key": "signing"},
    }
    variables["shutdown"] = {"grace_time": 600, "termination_grace_period_seconds": 630}
    variables["extra_values"] = {
        "podAnnotations": {"karpenter.sh/do-not-disrupt": "true"},
        "nodeSelector": {"karpenter.sh/nodepool": "test-protected"},
        "pdb": {"enabled": True, "minAvailable": 1},
    }
    (directory / "test.auto.tfvars.json").write_text(json.dumps(variables))
    encoded = run(["terraform", "console", "-no-color"], cwd=directory,
                  input="nonsensitive(jsonencode(local.chart_values))\n")
    values_file.write_text(json.dumps(json.loads(json.loads(encoded))))
    manifest = run(["helm", "template", "test-sftpgo", chart, "-f", str(values_file)])
    resources = json.loads(run(
        ["ruby", "-ryaml", "-rjson", "-e",
         "puts JSON.generate(YAML.load_stream(STDIN.read).compact)"], input=manifest,
    ))
    configmap = next(r for r in resources if r["kind"] == "ConfigMap")
    config = json.loads(configmap["data"]["sftpgo.json"])
    assert "signing_passphrase" not in config["httpd"]
    assert config["httpd"]["bindings"][0]["proxy_allowed"] == variables["web_proxy"]["proxy_allowed"]
    deployment = next(r for r in resources if r["kind"] == "Deployment")
    pod = deployment["spec"]["template"]
    assert pod["spec"]["terminationGracePeriodSeconds"] == 630
    assert pod["metadata"]["annotations"]["karpenter.sh/do-not-disrupt"] == "true"
    assert pod["spec"]["nodeSelector"] == {"karpenter.sh/nodepool": "test-protected"}
    assert [c["name"] for c in pod["spec"]["containers"]] == ["sftpgo"]
    env = {e["name"]: e for e in pod["spec"]["containers"][0]["env"]}
    assert env["SFTPGO_GRACE_TIME"]["value"] == "600"
    assert env["SFTPGO_HTTPD__SIGNING_PASSPHRASE"]["valueFrom"]["secretKeyRef"] == {
        "name": "test-session", "key": "signing",
    }
    assert env["AWS_ACCESS_KEY_ID"]["value"] == "test-key"
    pdb = next(r for r in resources if r["kind"] == "PodDisruptionBudget")
    assert pdb["apiVersion"] == "policy/v1"
    assert pdb["spec"]["minAvailable"] == 1
    assert "maxUnavailable" not in pdb["spec"]
    assert pdb["spec"]["selector"] == deployment["spec"]["selector"]

print("Pinned chart render passed: proxy, legacy sessions/bootstrap, Secret reference, disabled bootstrap, shutdown, PDB and placement.")
