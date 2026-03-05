locals {
  renovate_base_config = merge(
    {
      platform         = var.platform
      endpoint         = var.endpoint
      token            = var.token
      autodiscover     = var.autodiscover
      onboardingBranch = var.onboarding_branch
    },
    length(var.host_rules) > 0 ? { hostRules = var.host_rules } : {},
    length(var.package_rules) > 0 ? { packageRules = var.package_rules } : {}
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
