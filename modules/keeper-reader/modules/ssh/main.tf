data "secretsmanager_ssh_keys" "ssh" {
  path = var.uid
}

terraform {
  required_providers {
    secretsmanager = {
      source  = "keeper-security/secretsmanager"
      version = ">= 1.1.2"
    }
  }
}
