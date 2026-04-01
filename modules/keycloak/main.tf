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
    # NOTE(change): Keep both sides of the conditional the same object shape.
    # This avoids: "Inconsistent conditional result types".
    enabled          = false
    ingressClassName = null
    annotations      = {}
    rules            = []
    tls              = []
  }

  values = merge(
    {
      # NOTE(change): keycloakx chart only renders args when non-empty; otherwise the image may run
      # `kc.sh` with no subcommand (prints help, exits 0). Force server startup.
      args = ["start"]

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
        mode    = "forwarded"
        http = {
          enabled = true
        }
      }
      ingress = local.ingress_values
      extraEnv = yamlencode([
        {
          name  = "KEYCLOAK_ADMIN"
          value = var.admin_username
        },
        {
          name = "KEYCLOAK_ADMIN_PASSWORD"
          valueFrom = {
            secretKeyRef = {
              name = local.admin_password_secret_name
              key  = local.admin_password_secret_key
            }
          }
        },
        {
          name  = "KC_HOSTNAME"
          value = var.hostname
        },
        {
          # NOTE(change): Allow kubectl port-forward / alternative Host headers without redirects.
          name  = "KC_HOSTNAME_STRICT"
          value = var.hostname_strict ? "true" : "false"
        }
      ])
    },
    length(local.normalized_resources) > 0 ? { resources = local.normalized_resources } : {},
    length(var.pod_labels) > 0 ? { podLabels = var.pod_labels } : {}
  )
}

resource "kubernetes_namespace_v1" "this" {
  # NOTE(change): Helm's create_namespace happens at helm install time, but we create Secrets before
  # the helm release. So we manage the namespace here to avoid "namespace not found" for Secrets.
  count = var.create_namespace ? 1 : 0

  metadata {
    name = var.namespace
  }
}

resource "kubernetes_secret_v1" "admin_password" {
  count = var.admin_password != null ? 1 : 0

  # NOTE(change): Ensure namespace exists before Secret creation.
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

  # NOTE(change): Ensure namespace exists before Secret creation.
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

  name       = var.name
  repository = "https://codecentric.github.io/helm-charts"
  chart      = "keycloakx"
  namespace  = var.namespace
  version    = var.chart_version
  # NOTE(change): Namespace is created by kubernetes_namespace_v1 when create_namespace is true,
  # otherwise it must already exist.
  create_namespace = false

  atomic          = true
  cleanup_on_fail = true
  wait            = true
  # NOTE(change): Keycloak can take longer than Helm provider default (300s) to become ready.
  timeout = var.helm_timeout

  values = [
    yamlencode(local.values),
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
