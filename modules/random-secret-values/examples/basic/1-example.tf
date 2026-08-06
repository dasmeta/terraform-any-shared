module "authentik_values" {
  source = "../.."

  generated_values = {
    AUTHENTIK_SECRET_KEY = {
      length      = 64
      special     = true
      min_special = 1
    }
    AUTHENTIK_POSTGRESQL__PASSWORD = {
      length      = 32
      special     = true
      min_special = 1
    }
  }

  static_values = {
    username = "authentik_owner"
  }

  aliases = {
    password = "AUTHENTIK_POSTGRESQL__PASSWORD"
  }
}

output "keys" {
  value = module.authentik_values.keys
}

output "values" {
  value     = module.authentik_values.values
  sensitive = true
}
