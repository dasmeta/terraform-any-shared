module "authentik" {
  source = "../.."

  namespace                 = "test-platform"
  configuration_secret_name = "authentik-configuration"

  database = {
    host = "postgresql.test.internal"
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

output "server_service_http_port" {
  value = module.authentik.server_service_http_port
}
