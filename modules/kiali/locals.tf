locals {
  kiali_operator_enabled = var.configs.enabled && var.configs.operator.enabled
  kiali_cr_enabled       = var.configs.enabled && var.configs.cr.enabled

  kiali_prometheus_config = merge(
    {
      for key, value in {
        url              = try(var.configs.cr.external_services.prometheus.url, null)
        auth             = try(var.configs.cr.external_services.prometheus.auth, null)
        custom_headers   = try(var.configs.cr.external_services.prometheus.custom_headers, null)
        health_check_url = try(var.configs.cr.external_services.prometheus.health_check_url, null)
        is_core          = try(var.configs.cr.external_services.prometheus.is_core, null)
        query_scope      = try(var.configs.cr.external_services.prometheus.query_scope, null)
        thanos_proxy     = try(var.configs.cr.external_services.prometheus.thanos_proxy, null)
      } : key => value if value != null
    },
    try(var.configs.cr.external_services.prometheus.extra_configs, {})
  )

  kiali_grafana_config = merge(
    {
      for key, value in {
        enabled          = try(var.configs.cr.external_services.grafana.enabled, null)
        internal_url     = try(var.configs.cr.external_services.grafana.internal_url, null)
        external_url     = try(var.configs.cr.external_services.grafana.external_url, null)
        datasource_uid   = try(var.configs.cr.external_services.grafana.datasource_uid, null)
        dashboards       = try(var.configs.cr.external_services.grafana.dashboards, null)
        auth             = try(var.configs.cr.external_services.grafana.auth, null)
        health_check_url = try(var.configs.cr.external_services.grafana.health_check_url, null)
        is_core          = try(var.configs.cr.external_services.grafana.is_core, null)
      } : key => value if value != null
    },
    try(var.configs.cr.external_services.grafana.extra_configs, {})
  )

  kiali_external_services_config = merge(
    length(local.kiali_prometheus_config) > 0 ? { prometheus = local.kiali_prometheus_config } : {},
    length(local.kiali_grafana_config) > 0 ? { grafana = local.kiali_grafana_config } : {}
  )

  kiali_cr_base_spec = merge(
    {
      auth = {
        strategy = var.configs.cr.auth_strategy
      }
      deployment = merge(
        {
          namespace      = var.configs.cr.namespace
          view_only_mode = var.configs.cr.view_only_mode
        },
        var.configs.cr.deployment
      )
    },
    length(local.kiali_external_services_config) > 0 ? { external_services = local.kiali_external_services_config } : {}
  )

  kiali_cr_spec = merge(
    local.kiali_cr_base_spec,
    var.configs.cr.spec
  )
}
