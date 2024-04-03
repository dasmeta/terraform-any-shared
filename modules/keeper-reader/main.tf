locals {
  login_secrets = { for key, s in local.index : key => s if s.secret_type == "login" }
  db_secrets    = { for key, s in local.index : key => s if s.secret_type == "db" }
  ssh_secrets   = { for key, s in local.index : key => s if s.secret_type == "ssh" }
  index         = { for idx, val in var.secrets : idx => val }
}

module "login_secrets" {
  for_each = local.login_secrets

  source = "./modules/login"
  uid    = each.value.uid
}

module "db_secrets" {
  for_each = local.db_secrets

  source = "./modules/db"
  uid    = each.value.uid
}

module "ssh_secrets" {
  for_each = local.ssh_secrets

  source = "./modules/ssh"
  uid    = each.value.uid
}
