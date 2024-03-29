module "onepass" {
  source = "../"

  op_email           = "devops@dasmeta.com"
  op_password        = "************"
  op_secret_key      = "A3-**********"
  op_account_address = "https://my.1password.com"

  data = [
    {
      op_vault_name = "test"
      op_item       = "test-password"
    },
    {
      op_vault_name = "test"
      op_item       = "test2"

      // By default module use password type , but you use 1password categories (https://support.1password.com/item-categories/)
      op_item_type = "password"
    }
  ]
}

output "pass" {
  value     = module.onepass.pass
  sensitive = true
}
