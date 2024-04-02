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
      secret_key = "test"

      // By default module use password type , but you use 1password categories (https://support.1password.com/item-categories/)
      op_item_type = "password"
    },
    {
      op_vault_name = "test"
      op_item       = "test2"
      // Secret key in secret manager
      secret_key = "test2"

      // By default module use password type , but you use 1password categories (https://support.1password.com/item-categories/)
      op_item_type = "password"
    }
  ]
}
