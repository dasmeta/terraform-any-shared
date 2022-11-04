locals {
  config = templatefile("${path.module}/config.yaml", { platform = var.platform, endpoint = var.endpoint, token = var.token, autodiscover = var.autodiscover, branch_name = var.branch_name })
}

resource "helm_release" "renovate" {
  name      = var.name
  namespace = var.namespace

  repository = "https://docs.renovatebot.com/helm-charts"
  chart      = "renovate"

  values = [local.config]

  set {
    name  = "cronjob.schedule"
    value = var.schedule
  }
  set {
    name  = "env.GITHUB_COM_TOKEN"
    value = var.github_token
  }
}
