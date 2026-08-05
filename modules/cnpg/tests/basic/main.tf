module "cnpg" {
  source = "../.."

  name      = "test-postgres"
  namespace = "test-platform"
  instances = 2

  storage = {
    class = "hcloud-volumes"
    size  = "10Gi"
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

output "ro_service_hostname" {
  value = module.cnpg.ro_service_hostname
}
