locals {
  default_host_rules = {
    gitlab = [
      {
        matchHost = "https://gitlab.com"
        token     = var.token
        hostType  = "maven"
      }
    ]
  }
  host_rules = concat(lookup(local.default_host_rules, var.platform, []), var.host_rules)
  package_rules = [for rule in var.package_rules :
    { for k, v in rule : k => v if v != null }
  ]

  renovate_base_config = merge(
    {
      platform         = var.platform
      endpoint         = var.endpoint
      token            = var.token
      autodiscover     = var.autodiscover
      onboardingBranch = var.onboarding_branch
    },
    length(local.host_rules) > 0 ? { hostRules = local.host_rules } : {},
    length(local.package_rules) > 0 ? { packageRules = local.package_rules } : {}
  )
  extra_config_decoded = try(jsondecode(var.extra_config), {})
  renovate_config      = merge(local.renovate_base_config, local.extra_config_decoded)
  renovate_config_json = jsonencode(local.renovate_config)

  default_helm_values = {
    renovate = {
      config = local.renovate_config_json
    }
    cronjob = {
      schedule = var.schedule
    }
    env = {
      GITHUB_COM_TOKEN = var.github_token
    }
  }
}
