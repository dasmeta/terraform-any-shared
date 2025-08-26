### Keeper-Reader Module
This module is designed to read data from Keeper Security. Keeper stores various types of secrets. Currently, this module supports three types:
- Login
- SSH
- Database

To retrieve a secret value from each record, specify the UID and the record type. Ensure the `secret_type` is set appropriately:
Make sure the `secret_type` is
- Use `login` for Login record types.
- Use `ssh` for SSH record types.
- Use `db` for Database record types.


### Basic Usage Example
```
module "this" {
  source = "dasmeta/shared/any//modules/keeper-reader"

  secrets = [
    {
      secret_type = "ssh"
      uid         = "Q01idnfdzL9E61qh1Jb4pg"
    },
    {
      secret_type = "login"
      uid         = "zQpkIafNN-oAput14LhSVA"
    },
    {
      secret_type = "db"
      uid         = "MCibEDNanLDVsYvqlo3Ovw"
    },
  ]
  keeper_credentials = "/path/to/keeper/config.json"
}
```
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_secretsmanager"></a> [secretsmanager](#requirement\_secretsmanager) | 1.1.3 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_db_secrets"></a> [db\_secrets](#module\_db\_secrets) | ./modules/db | n/a |
| <a name="module_login_secrets"></a> [login\_secrets](#module\_login\_secrets) | ./modules/login | n/a |
| <a name="module_ssh_secrets"></a> [ssh\_secrets](#module\_ssh\_secrets) | ./modules/ssh | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_secrets"></a> [secrets](#input\_secrets) | List of secrets to fetch from Keeper Security | <pre>list(object({<br/>    secret_type = string # Record type for each one<br/>    uid         = string # UID of a specific secret record<br/>  }))</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_all_secrets"></a> [all\_secrets](#output\_all\_secrets) | n/a |
| <a name="output_db_secrets"></a> [db\_secrets](#output\_db\_secrets) | n/a |
| <a name="output_login_secrets"></a> [login\_secrets](#output\_login\_secrets) | n/a |
| <a name="output_ssh_secrets"></a> [ssh\_secrets](#output\_ssh\_secrets) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
