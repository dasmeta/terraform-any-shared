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