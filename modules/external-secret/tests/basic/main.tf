module "application_secret" {
  source = "../.."

  name      = "test-configuration"
  namespace = "test-platform"

  secret_store = {
    name = "test-store"
  }

  remote_key = "test/configuration"

  target = {
    name = "test-configuration"
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
