locals {
  value = { for k, item in var.data : item.secret_key => module.onepass.pass[k] }
}


module "onepass" {
  source = "dasmeta/shared/any//modules/onepassword"

  op_email      = var.op_email
  op_password   = var.op_password
  op_secret_key = var.op_secret_key

  data = var.data
}

module "secret" {
  source = "dasmeta/modules/aws//modules/secret"

  name  = var.aws_secret_name
  value = local.value
}
