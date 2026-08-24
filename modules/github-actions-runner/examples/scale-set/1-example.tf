module "runner" {
  source = "../.."

  deployment_mode         = "scale_set"
  namespace               = "github-actions-runner"
  personal_access_token   = null
  github_auth_secret_name = "controller-manager"
  kubectl_config_path     = null

  scale_set = {
    github_config_url        = "https://github.com/example"
    runner_scale_set_name    = "example-runners"
    min_runners              = 1
    max_runners              = 3
    controller_chart_version = "0.14.2"
    chart_version            = "0.14.2"
  }
}

output "runner_scale_set_name" {
  value = module.runner.runner_scale_set_name
}
