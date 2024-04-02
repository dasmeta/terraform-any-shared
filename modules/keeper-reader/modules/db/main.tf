data "secretsmanager_database_credentials" "database_credentials" {
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
