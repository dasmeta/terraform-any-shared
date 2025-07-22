locals {
  default_host_rules = {
    gitlab = [
      {
        matchHost = "https://gitlab.com",
        token     = var.token,
        hostType  = "maven"
      }
    ]
  }
  host_rules = concat(lookup(local.default_host_rules, var.platform, []), var.host_rules)
  package_rules = [for rule in var.package_rules :
    { for key, value in rule :
      key => value if value != null
    }
  ]
  config = templatefile("${path.module}/config.yaml", { platform = var.platform, endpoint = var.endpoint, token = var.token, autodiscover = var.autodiscover, branch_name = var.branch_name, host_rules = local.host_rules, package_rules = local.package_rules })
}

resource "helm_release" "renovate" {
  name      = var.name
  namespace = var.namespace

  repository = "https://docs.renovatebot.com/helm-charts"
  chart      = "renovate"
  version    = var.helm_version

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
