locals {
  ingress_enabled = try(var.ingress.enabled, true)

  server_ingress = local.ingress_enabled ? merge(
    {
      enabled          = true
      controller       = "aws"
      ingressClassName = "alb"
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
    controller       = "aws"
    ingressClassName = "alb"
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

  configs_params = {
    "server.insecure" = "true"
  }

  values = {
    server = { ingress = local.server_ingress }
    configs = {
      secret = local.configs_secret
      params = local.configs_params
    }
  }
}

resource "kubernetes_namespace_v1" "this" {
  count = var.create_namespace ? 1 : 0

  metadata {
    name = var.namespace
  }
}

resource "helm_release" "this" {
  depends_on = [kubernetes_namespace_v1.this]

  name             = var.name
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = var.namespace
  version          = var.chart_version
  create_namespace = false

  atomic          = true
  cleanup_on_fail = true
  wait            = true
  timeout         = var.helm_timeout

  values = [
    yamlencode(local.values),
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
