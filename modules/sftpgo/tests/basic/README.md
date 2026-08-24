# Basic SFTPGo validation fixture

This fixture validates the module interface with S3-backed storage, admin
bootstrap, one bootstrap user, and optional SFTP-only LoadBalancer exposure. It
also validates the stable WebUI session settings. It is intended for Terraform
static validation, not for applying against a shared cluster as-is.

```bash
terraform init -backend=false
terraform validate
```
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
