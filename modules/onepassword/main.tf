module "onepassword" {
  for_each = { for one in var.data : one.op_item => one }

  source             = "./module/get-data"
  op_secret_key      = var.op_secret_key
  op_password        = var.op_password
  op_account_address = var.op_account_address
  op_email           = var.op_email
  op_item            = each.value.op_item
  op_vault_name      = each.value.op_vault_name
  op_item_type       = lookup(each.value, "op_item_type", "password")
}

output "pass" {
  value     = values(module.onepassword)[*].pass
  sensitive = true
}
