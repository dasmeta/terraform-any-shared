module "cnpg" {
  source = "../.."

  name      = "application-postgres"
  namespace = "application"
  instances = 3

  storage = {
    class = "hcloud-volumes"
    size  = "20Gi"
  }

  database = {
    name                  = "application"
    owner                 = "application_owner"
    bootstrap_secret_name = "application-postgres-owner"
  }
}

output "rw_service_hostname" {
  value = module.cnpg.rw_service_hostname
}
