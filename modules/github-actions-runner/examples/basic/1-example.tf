module "runner" {
  source = "../.."

  runner_name             = "example-runner"
  personal_access_token   = null
  github_auth_secret_name = "controller-manager"
  kubectl_config_path     = null
  chart_version           = "0.23.7"

  runner_scope = {
    organization = "example"
  }
}

output "runner_resource_names" {
  value = module.runner.runner_resource_names
}
