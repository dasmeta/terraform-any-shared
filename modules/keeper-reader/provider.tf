terraform {
  required_providers {
    secretsmanager = {
      source  = "keeper-security/secretsmanager"
      version = ">= 1.1.2"
    }
  }
}

provider "secretsmanager" {
  credential = file("${var.keeper_credentials}")
}
