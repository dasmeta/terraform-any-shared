module "authentik" {
  source = "../.."

  namespace                 = "example-platform"
  configuration_secret_name = "authentik-configuration"

  database = {
    host = "postgresql.example.internal"
    name = "authentik"
    user = "authentik"
  }

  extra_helm_config = {
    server = {
      replicas = 2
    }
  }
}

output "server_service_name" {
  value = module.authentik.server_service_name
}
