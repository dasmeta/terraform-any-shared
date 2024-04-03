data "secretsmanager_login" "login" {
  path = var.uid
}

terraform {
  required_providers {
    secretsmanager = {
      source  = "Keeper-Security/secretsmanager"
      version = "1.1.3"
    }
  }
}
