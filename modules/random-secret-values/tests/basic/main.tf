module "values" {
  source = "../.."

  generated_values = {
    application_key = {
      length      = 48
      special     = true
      min_special = 1
    }
    database_password = {
      length      = 24
      special     = true
      min_numeric = 1
    }
  }

  static_values = {
    username = "application_owner"
  }

  aliases = {
    password = "database_password"
  }
}

output "keys" {
  value = module.values.keys
}

output "values" {
  value     = module.values.values
  sensitive = true
}
