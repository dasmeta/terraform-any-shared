locals {
  values_file  = var.values_file != null ? file(var.values_file) : ""
  repository   = "https://charts.gitlab.io"
  chart_name   = "gitlab-runner"
  runner_token = var.runner_registration_token == null ? var.runner_token : null
  replicas     = var.runner_token != null ? 1 : var.replicas
}
