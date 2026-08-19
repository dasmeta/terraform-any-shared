module "application_secret" {
  source = "../.."

  name      = "application-configuration"
  namespace = "application"

  secret_store = {
    name = "application-store"
  }

  remote_key = "application/configuration"

  target = {
    name = "application-configuration"
    type = "Opaque"
  }

  mappings = [
    {
      secret_key      = "configuration_value"
      remote_property = "configuration_value"
    },
  ]
}

output "target_secret_name" {
  value = module.application_secret.target_secret_name
}
