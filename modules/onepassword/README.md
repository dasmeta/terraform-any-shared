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
