### Use module when you want get your secrets from 1password

## Pre Required

Install op-cli https://1password.com/downloads/command-line/

## Usage

```
module "onepass" {
  source = "dasmeta/shared/any//modules/onepassword"

  op_email      = "devops@dasmeta.com"
  op_password   = "************"
  op_secret_key = "A3-**********"

  data = [
    {
      op_vault_name = "test"
      op_item       = "test-password"
    },
    {
      op_vault_name = "test"
      op_item       = "test-password2"
    }
  ]
}
```
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

No requirements.

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_onepassword"></a> [onepassword](#module\_onepassword) | ./module/get-data | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_data"></a> [data](#input\_data) | OnePassword vault name and item name object. The Item should be in Vault | `list(any)` | n/a | yes |
| <a name="input_op_account_address"></a> [op\_account\_address](#input\_op\_account\_address) | OnePassword account address | `string` | `"https://my.1password.com"` | no |
| <a name="input_op_email"></a> [op\_email](#input\_op\_email) | OnePassword user email | `string` | n/a | yes |
| <a name="input_op_password"></a> [op\_password](#input\_op\_password) | OnePassword user password | `string` | n/a | yes |
| <a name="input_op_secret_key"></a> [op\_secret\_key](#input\_op\_secret\_key) | OnePassword user secret key | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_pass"></a> [pass](#output\_pass) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
