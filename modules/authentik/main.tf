locals {
  ingress_annotations = merge(
    var.ingress.annotations,
    var.ingress.enabled ? {
      "cert-manager.io/cluster-issuer"                 = var.ingress.cluster_issuer
      "nginx.ingress.kubernetes.io/force-ssl-redirect" = "true"
    } : {},
  )

  values = {
    fullnameOverride = var.name

    global = {
      env = [
        {
          name  = "AUTHENTIK_POSTGRESQL__HOST"
          value = var.database.host
        },
        {
          name  = "AUTHENTIK_POSTGRESQL__NAME"
          value = var.database.name
        },
        {
          name  = "AUTHENTIK_POSTGRESQL__USER"
          value = var.database.user
        },
        {
          name  = "AUTHENTIK_POSTGRESQL__PORT"
          value = tostring(var.database.port)
        },
      ]
    }

    authentik = {
      existingSecret = {
        secretName = var.configuration_secret_name
      }
    }

    postgresql = {
      enabled = false
    }

    server = {
      service = {
        type            = "ClusterIP"
        servicePortHttp = 80
      }

      ingress = {
        enabled          = var.ingress.enabled
        annotations      = local.ingress_annotations
        ingressClassName = var.ingress.class_name
        hosts            = var.ingress.enabled ? [var.ingress.hostname] : []
        tls = var.ingress.enabled ? [{
          secretName = var.ingress.tls_secret_name
          hosts      = [var.ingress.hostname]
        }] : []
      }
    }
  }
}

resource "helm_release" "this" {
  name             = var.name
  repository       = "https://charts.goauthentik.io"
  chart            = "authentik"
  namespace        = var.namespace
  version          = var.chart_version
  create_namespace = false

  atomic          = true
  cleanup_on_fail = true
  wait            = true
  timeout         = 900

  values = [
    yamlencode(var.extra_helm_config),
    yamlencode(local.values),
  ]
}
