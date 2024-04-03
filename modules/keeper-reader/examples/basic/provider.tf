terraform {
  required_providers {
    secretsmanager = {
      source  = "Keeper-Security/secretsmanager"
      version = "1.1.3"
    }
  }
}

provider "secretsmanager" {
  credential = file("/path/to/keeper/config.json")
}
