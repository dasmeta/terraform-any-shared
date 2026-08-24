# Basic SFTPGo example

This example deploys SFTPGo with S3-backed bootstrap user storage.

It mirrors the common environment deployment shape: AWS, Kubernetes, and Helm
providers authenticate to an EKS cluster, while the module receives S3
credentials, admin bootstrap credentials, image pull secrets, persistence,
ALB ingress, resources, bootstrap user settings, and stable WebUI session
settings.

Replace the placeholder variable values before applying. Sensitive inputs are
redacted in normal Terraform output, but they still exist in Terraform state.
The WebUI signing passphrase must remain stable across pod restarts.

```bash
terraform init
terraform plan
```
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.23 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_sftpgo"></a> [sftpgo](#module\_sftpgo) | ../.. | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_access_key"></a> [aws\_access\_key](#input\_aws\_access\_key) | AWS access key for the example provider. | `string` | n/a | yes |
| <a name="input_aws_secret_key"></a> [aws\_secret\_key](#input\_aws\_secret\_key) | AWS secret key for the example provider. | `string` | n/a | yes |
| <a name="input_cluster_ca_certificate"></a> [cluster\_ca\_certificate](#input\_cluster\_ca\_certificate) | Base64-encoded EKS cluster CA certificate. | `string` | n/a | yes |
| <a name="input_cluster_host"></a> [cluster\_host](#input\_cluster\_host) | EKS cluster API endpoint. | `string` | n/a | yes |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | EKS cluster name used by provider exec authentication. | `string` | `"eks-dev"` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region used by the EKS cluster and S3 bucket. | `string` | `"eu-central-1"` | no |
| <a name="input_sftpgo_admin_password"></a> [sftpgo\_admin\_password](#input\_sftpgo\_admin\_password) | Initial SFTPGo admin password. | `string` | n/a | yes |
| <a name="input_sftpgo_demo_user_password"></a> [sftpgo\_demo\_user\_password](#input\_sftpgo\_demo\_user\_password) | Bootstrap password for the demo SFTPGo user. | `string` | n/a | yes |
| <a name="input_sftpgo_s3_access_key"></a> [sftpgo\_s3\_access\_key](#input\_sftpgo\_s3\_access\_key) | S3 access key used by SFTPGo bootstrap users. | `string` | n/a | yes |
| <a name="input_sftpgo_s3_access_secret"></a> [sftpgo\_s3\_access\_secret](#input\_sftpgo\_s3\_access\_secret) | S3 access secret used by SFTPGo bootstrap users. | `string` | n/a | yes |
| <a name="input_sftpgo_web_session_signing_passphrase"></a> [sftpgo\_web\_session\_signing\_passphrase](#input\_sftpgo\_web\_session\_signing\_passphrase) | Stable signing passphrase for SFTPGo WebAdmin and WebClient sessions. | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
