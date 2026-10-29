# Basic SFTPGo validation fixture

This fixture validates the module interface with S3-backed storage, admin
bootstrap, one bootstrap user, and optional SFTP-only LoadBalancer exposure. It
also validates the stable WebUI session and trusted HTTP proxy settings. It is intended for Terraform
static validation, not for applying against a shared cluster as-is.

```bash
terraform init -backend=false
terraform validate
```

From the module directory, run the plan-only proxy regression suite with
Terraform 1.7 or newer (mock providers; no cluster credentials or deployment):

```bash
terraform init -backend=false
terraform test -filter=tests/web_proxy.tftest.hcl
```

Run `terraform test -filter=tests/sftp_service.tftest.hcl` from the module directory
for SFTP Service routing tests. They cover Local LoadBalancer/NodePort, default
and explicit Cluster, omitted policy for ClusterIP, invalid inputs and disabled
Service behavior. The ClusterIP test performs a mocked apply only to resolve the
provider's computed field; no real infrastructure is contacted or changed.

The suite checks omitted inputs, combined proxy/session settings, enabled HTTP
interfaces, preserved ingress/bootstrap configuration, IPv6/custom proxy chains,
and invalid trust lists/header depths. The module itself still supports Terraform
`~> 1.3`; the newer version is only required for mock-provider tests.

Render the actual pinned chart with Terraform-generated values (requires Helm,
Python 3 and Ruby with its standard YAML library):

```bash
helm pull oci://ghcr.io/sftpgo/helm-charts/sftpgo --version 0.45.0 --destination /tmp
python3 tests/render_web_proxy_test.py /tmp/sftpgo-0.45.0.tgz
```

Run `terraform test -filter=tests/hardening.tftest.hcl` for signing Secret source
validation, disabled bootstrap and paired shutdown settings. The chart render
also verifies the Secret reference without a ConfigMap literal, omitted bootstrap
container, custom shutdown periods, PDB selector, pod annotation and node selector.
These are configuration tests; they do not prove live NLB draining or upload
completion during an actual node drain.
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_sftpgo"></a> [sftpgo](#module\_sftpgo) | ../../ | n/a |

## Resources

No resources.

## Inputs

No inputs.

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
