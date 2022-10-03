### Pre Required

Install op-cli https://1password.com/downloads/command-line/

## Usage

```
module "onepass" {
  source = "dasmeta/shared/any//modules/onepass"

  op_email      = "aram@dasmeta.com"
  op_password   = "VKcf*****a3hLAs"
  op_secret_key = "A3-CDN******RN"

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
