locals {
  admin_password_secret_name = var.admin_password_secret_name != null ? var.admin_password_secret_name : "${var.name}-admin-password"
  admin_password_secret_key  = var.admin_password_secret_key

  database_password_secret_name = try(var.database.password_secret_name, null) != null ? var.database.password_secret_name : "${var.name}-database-password"
  database_password_secret_key  = try(var.database.password_secret_key, "password")

  normalized_resources = merge(
    length(try(var.resources.limits, {})) > 0 ? { limits = var.resources.limits } : {},
    length(try(var.resources.requests, {})) > 0 ? { requests = var.resources.requests } : {}
  )

  ingress_enabled = try(var.ingress.enabled, true)
  ingress_values = local.ingress_enabled ? {
    enabled          = true
    ingressClassName = try(var.ingress.ingress_class_name, null)
    annotations      = try(var.ingress.annotations, {})
    rules = [
      {
        host = var.hostname
        paths = [
          {
            path     = try(var.ingress.path, "/")
            pathType = try(var.ingress.path_type, "Prefix")
          }
        ]
      }
    ]
    tls = try(var.ingress.tls_secret_name, null) != null ? [
      {
        hosts      = [var.hostname]
        secretName = var.ingress.tls_secret_name
      }
    ] : []
    } : {
    enabled          = false
    ingressClassName = null
    annotations      = {}
    rules            = []
    tls              = []
  }

  # TLS at ALB/ingress: browser uses https:// while the pod sees plain HTTP. Keycloak must treat the
  # public URL as HTTPS (KC_HOSTNAME as full URL or scheme from trusted X-Forwarded-*). Otherwise it
  # may redirect HTTP→HTTPS in a loop (same class of issue as insecure/passthrough behind a proxy).
  kc_hostname_value = coalesce(
    var.hostname_public_url,
    (local.ingress_enabled && var.assume_https_public_endpoint) ? "https://${var.hostname}" : var.hostname,
  )

  kc_log_level = length(var.log_categories) > 0 ? "${var.log_level},${join(",", [for k in sort(keys(var.log_categories)) : "${k}:${var.log_categories[k]}"])}" : var.log_level

  java_opts_append_combined = trimspace(join(" ", compact([
    var.prefer_ipv4 ? "-Djava.net.preferIPv4Stack=true" : null,
    length(trimspace(var.java_opts_append)) > 0 ? trimspace(var.java_opts_append) : null,
  ])))

  extra_env_list = concat(
    [
      { name = "KEYCLOAK_ADMIN", value = var.admin_username },
      {
        name = "KEYCLOAK_ADMIN_PASSWORD"
        valueFrom = {
          secretKeyRef = {
            name = local.admin_password_secret_name
            key  = local.admin_password_secret_key
          }
        }
      },
      { name = "KC_HOSTNAME", value = local.kc_hostname_value },
      { name = "KC_HOSTNAME_STRICT", value = var.hostname_strict ? "true" : "false" },
      { name = "KC_LOG_LEVEL", value = local.kc_log_level },
    ],
    var.hostname_admin_url != null ? [{ name = "KC_HOSTNAME_ADMIN", value = var.hostname_admin_url }] : [],
    var.hostname_backchannel_dynamic ? [{ name = "KC_HOSTNAME_BACKCHANNEL_DYNAMIC", value = "true" }] : [],
    var.http_max_queued_requests != null ? [{ name = "KC_HTTP_MAX_QUEUED_REQUESTS", value = tostring(var.http_max_queued_requests) }] : [],
    var.http_metrics_slos != null ? [{ name = "KC_HTTP_METRICS_SLOS", value = var.http_metrics_slos }] : [],
    var.event_metrics.enabled ? concat(
      [{ name = "KC_EVENT_METRICS_USER_ENABLED", value = "true" }],
      try(var.event_metrics.user_events, null) != null ? [{ name = "KC_EVENT_METRICS_USER_EVENTS", value = var.event_metrics.user_events }] : [],
      try(var.event_metrics.user_tags, null) != null ? [{ name = "KC_EVENT_METRICS_USER_TAGS", value = var.event_metrics.user_tags }] : [],
    ) : [],
    var.http_metrics_histograms ? [{ name = "KC_HTTP_METRICS_HISTOGRAMS_ENABLED", value = "true" }] : [],
    var.cache_metrics_histograms ? [{ name = "KC_CACHE_METRICS_HISTOGRAMS_ENABLED", value = "true" }] : [],
    length(local.java_opts_append_combined) > 0 ? [{ name = "JAVA_OPTS_APPEND", value = local.java_opts_append_combined }] : [],
    var.extra_env,
  )

  service_monitor_values = merge(
    {
      enabled           = var.service_monitor.enabled
      interval          = var.service_monitor.interval
      scrapeTimeout     = var.service_monitor.scrape_timeout
      labels            = var.service_monitor.labels
      annotations       = var.service_monitor.annotations
      relabelings       = var.service_monitor.relabelings
      metricRelabelings = var.service_monitor.metric_relabelings
    },
    try(var.service_monitor.namespace, "") != "" ? { namespace = var.service_monitor.namespace } : {},
    length(try(var.service_monitor.namespace_selector, {})) > 0 ? { namespaceSelector = var.service_monitor.namespace_selector } : {},
  )

  values = merge(
    {
      args     = ["start"]
      replicas = var.replicas
      http = {
        relativePath = "/"
      }
      dbchecker = {
        enabled = true
      }
      database = {
        vendor            = try(var.database.vendor, "postgres")
        hostname          = var.database.host
        port              = try(var.database.port, 5432)
        database          = var.database.name
        username          = var.database.username
        existingSecret    = local.database_password_secret_name
        existingSecretKey = local.database_password_secret_key
      }
      proxy = {
        enabled = true
        mode    = var.proxy_mode
        http = {
          enabled = true
        }
      }
      cache = {
        stack = var.cache_stack
      }
      metrics = {
        enabled = var.metrics_enabled
      }
      health = {
        enabled = var.health_enabled
      }
      serviceMonitor = local.service_monitor_values
      ingress        = local.ingress_values
      extraEnv       = yamlencode(local.extra_env_list)
    },
    length(local.normalized_resources) > 0 ? { resources = local.normalized_resources } : {},
    length(var.pod_labels) > 0 ? { podLabels = var.pod_labels } : {},
    length(var.pod_annotations) > 0 ? { podAnnotations = var.pod_annotations } : {},
    length(var.service_annotations) > 0 ? { service = { annotations = var.service_annotations } } : {},
    var.termination_grace_period_seconds != null ? { terminationGracePeriodSeconds = var.termination_grace_period_seconds } : {},
    var.pod_disruption_budget != null ? { podDisruptionBudget = var.pod_disruption_budget } : {},
  )
}

resource "kubernetes_namespace_v1" "this" {
  count = var.create_namespace ? 1 : 0

  metadata {
    name = var.namespace
  }
}

resource "kubernetes_secret_v1" "admin_password" {
  count = var.admin_password != null ? 1 : 0

  depends_on = [kubernetes_namespace_v1.this]

  metadata {
    name      = local.admin_password_secret_name
    namespace = var.namespace
  }

  type = "Opaque"

  data = {
    (local.admin_password_secret_key) = var.admin_password
  }
}

resource "kubernetes_secret_v1" "database_password" {
  count = try(var.database.password, null) != null ? 1 : 0

  depends_on = [kubernetes_namespace_v1.this]

  metadata {
    name      = local.database_password_secret_name
    namespace = var.namespace
  }

  type = "Opaque"

  data = {
    (local.database_password_secret_key) = var.database.password
  }
}

resource "helm_release" "this" {
  depends_on = [
    kubernetes_namespace_v1.this,
    kubernetes_secret_v1.admin_password,
    kubernetes_secret_v1.database_password,
  ]

  name             = var.name
  repository       = "https://codecentric.github.io/helm-charts"
  chart            = "keycloakx"
  namespace        = var.namespace
  version          = var.chart_version
  create_namespace = false

  atomic          = var.atomic
  cleanup_on_fail = var.cleanup_on_fail
  wait            = var.wait
  timeout         = var.helm_timeout

  values = [
    yamlencode(local.values),
    yamlencode(var.extra_configs),
  ]

  lifecycle {
    precondition {
      condition     = (var.admin_password != null) != (var.admin_password_secret_name != null)
      error_message = "Set exactly one of admin_password or admin_password_secret_name."
    }

    precondition {
      condition     = (try(var.database.password, null) != null) != (try(var.database.password_secret_name, null) != null)
      error_message = "Set exactly one of database.password or database.password_secret_name."
    }
  }
}
