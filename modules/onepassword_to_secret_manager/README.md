### Use module when you want integrate 1password to AWS Secret manager
### The module pull 1password items credential and will create new secrets in AWS

## Pre Required

Install op-cli https://1password.com/downloads/command-line/

## Usage


```
module "onepassword_to_secret_manager" {
  source = "dasmeta/shared/any//modules/onepassword_to_secret_manager"

  op_email      = "devops@dasmeta.com"
  op_password   = "************"
  op_secret_key = "A3-**********"

  aws_secret_name = "secret_name"

  data = [
    {
      op_vault_name = "test"
      op_item       = "test-password"
      // Secret key in secret manager
      secret_key    = "test"
    },
    {
      op_vault_name = "test"
      op_item       = "test2"
      // Secret key in secret manager
      secret_key    = "test2"
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
| <a name="module_onepass"></a> [onepass](#module\_onepass) | dasmeta/shared/any//modules/onepassword | n/a |
| <a name="module_secret"></a> [secret](#module\_secret) | dasmeta/modules/aws//modules/secret | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_secret_name"></a> [aws\_secret\_name](#input\_aws\_secret\_name) | AWS Secret name | `string` | n/a | yes |
| <a name="input_data"></a> [data](#input\_data) | OnePassword vault name and item name object. The Item should be in Vault | `list(any)` | <pre>[<br>  {<br>    "op_item": "test-password",<br>    "op_vault_name": "test",<br>    "secret_key": "test"<br>  }<br>]</pre> | no |
| <a name="input_op_account_address"></a> [op\_account\_address](#input\_op\_account\_address) | OnePassword account address | `string` | `"https://my.1password.com"` | no |
| <a name="input_op_email"></a> [op\_email](#input\_op\_email) | OnePassword user email | `string` | n/a | yes |
| <a name="input_op_password"></a> [op\_password](#input\_op\_password) | OnePassword user password | `string` | n/a | yes |
| <a name="input_op_secret_key"></a> [op\_secret\_key](#input\_op\_secret\_key) | OnePassword user secret key | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
