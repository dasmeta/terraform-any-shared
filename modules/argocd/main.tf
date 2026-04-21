locals {
  ingress_enabled = try(var.ingress.enabled, true)

  server_ingress = local.ingress_enabled ? merge(
    {
      enabled          = true
      controller       = try(var.ingress.controller, "aws")
      ingressClassName = try(var.ingress.ingress_class_name, "alb")
      annotations      = try(var.ingress.annotations, {})
      hostname         = var.hostname
      path             = try(var.ingress.path, "/")
      pathType         = try(var.ingress.path_type, "Prefix")
    },
    try(var.ingress.tls_secret_name, null) != null ? {
      extraTls = [
        {
          hosts      = [var.hostname]
          secretName = var.ingress.tls_secret_name
        }
      ]
    } : {}
    ) : {
    enabled          = false
    controller       = try(var.ingress.controller, "aws")
    ingressClassName = try(var.ingress.ingress_class_name, "alb")
    annotations      = {}
    hostname         = null
    path             = "/"
    pathType         = "Prefix"
  }

  configs_secret = merge(
    {
      createSecret = var.use_existing_admin_secret ? false : true
    },
    var.admin_password_bcrypt != null ? {
      argocdServerAdminPassword      = var.admin_password_bcrypt
      argocdServerAdminPasswordMtime = ""
    } : {}
  )

  configs_params = local.ingress_enabled ? {
    "server.insecure" = "true"
  } : {}

  server_autoscaling = {
    enabled                           = try(var.autoscaling.enabled, false)
    minReplicas                       = try(var.autoscaling.min_replicas, 1)
    maxReplicas                       = try(var.autoscaling.max_replicas, 5)
    targetCPUUtilizationPercentage    = try(var.autoscaling.target_cpu_utilization_percentage, 50)
    targetMemoryUtilizationPercentage = try(var.autoscaling.target_memory_utilization_percentage, 50)
    behavior                          = try(var.autoscaling.behavior, {})
    metrics                           = try(var.autoscaling.metrics, [])
  }

  values = {
    server = {
      ingress     = local.server_ingress
      replicas    = var.replicas
      resources   = var.resources
      autoscaling = local.server_autoscaling
    }
    configs = {
      secret = local.configs_secret
      params = local.configs_params
    }
  }
}

resource "helm_release" "this" {
  name             = var.name
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = var.namespace
  version          = var.chart_version
  create_namespace = var.create_namespace

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
      condition     = (var.admin_password_bcrypt != null) != (var.use_existing_admin_secret)
      error_message = "Set exactly one of admin_password_bcrypt or use_existing_admin_secret=true."
    }

    precondition {
      condition     = !local.ingress_enabled || (var.hostname != null && var.hostname != "")
      error_message = "When ingress is enabled, hostname must be set."
    }
  }
}
