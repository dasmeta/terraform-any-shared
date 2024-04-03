data "secretsmanager_ssh_keys" "ssh" {
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
