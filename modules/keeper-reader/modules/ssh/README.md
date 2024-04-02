# ssh

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_secretsmanager"></a> [secretsmanager](#requirement\_secretsmanager) | >= 1.1.2 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_secretsmanager"></a> [secretsmanager](#provider\_secretsmanager) | >= 1.1.2 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [secretsmanager_ssh_keys.ssh](https://registry.terraform.io/providers/keeper-security/secretsmanager/latest/docs/data-sources/ssh_keys) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_uid"></a> [uid](#input\_uid) | UID of the ssh secret | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_secret_data"></a> [secret\_data](#output\_secret\_data) | The fetched secret data |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
