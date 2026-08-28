module "authentik" {
  source = "../.."

  namespace                 = "example-platform"
  configuration_secret_name = "authentik-configuration"

  database = {
    host = "postgresql.example.internal"
    name = "authentik"
    user = "authentik"
  }

  ingress = {
    enabled         = true
    hostname        = "auth.example.com"
    tls_secret_name = "auth-example-com-tls"
    cluster_issuer  = "letsencrypt-prod"
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
