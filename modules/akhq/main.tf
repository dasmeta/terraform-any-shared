locals {
  normalized_resources = merge(
    length(try(var.resources.limits, {})) > 0 ? { limits = var.resources.limits } : {},
    length(try(var.resources.requests, {})) > 0 ? { requests = var.resources.requests } : {}
  )

  use_chart_secrets = var.existing_secrets == null || var.existing_secrets == ""

  generate_jwt = var.security.enabled && local.use_chart_secrets && var.security.micronaut_jwt_secret == null

  micronaut_jwt_secret = coalesce(
    var.security.micronaut_jwt_secret,
    try(random_password.micronaut_jwt[0].result, "")
  )

  kafka_connection_properties = merge(
    { "bootstrap.servers" = var.kafka.bootstrap_servers },
    var.kafka.properties
  )

  # Optional SCRAM user/pass builds sasl.jaas.config; entries in kafka_secret_properties win on key clash.
  kafka_scram_jaas_properties = (
    var.kafka_scram_username != null && var.kafka_scram_username != "" &&
    var.kafka_scram_password != null && var.kafka_scram_password != ""
    ) ? {
    "sasl.jaas.config" = format(
      "org.apache.kafka.common.security.scram.ScramLoginModule required username=\"%s\" password=\"%s\";",
      var.kafka_scram_username,
      var.kafka_scram_password,
    )
  } : {}

  kafka_secret_properties_effective = merge(local.kafka_scram_jaas_properties, var.kafka_secret_properties)

  configuration = merge(
    {
      akhq = merge(
        {
          server = {
            access-log = {
              enabled = true
              name    = "org.akhq.log.access"
            }
          }
          connections = {
            (var.kafka.connection_name) = {
              properties = local.kafka_connection_properties
            }
          }
        },
        var.security.enabled ? {
          security = {
            enabled       = true
            default-group = "no-roles"
          }
        } : {}
      )
    },
    var.security.enabled ? {
      micronaut = {
        security = {
          enabled = true
        }
      }
    } : {},
    var.extra_configuration
  )

  # AKHQ expects basic-auth passwords as SHA-256 hex (default) or bcrypt; see
  # https://akhq.io/docs/configuration/authentifications/basic-auth.html
  basic_auth_password_for_chart = try(var.security.basic_auth_password_prehashed, false) ? var.security.basic_auth_password : (
    var.security.basic_auth_password == null ? "" : sha256(var.security.basic_auth_password)
  )

  akhq_secret_block = merge(
    var.security.enabled && local.use_chart_secrets ? {
      security = {
        basic-auth = [
          {
            username = var.security.basic_auth_username
            password = local.basic_auth_password_for_chart
            groups   = var.security.basic_auth_groups
          }
        ]
      }
    } : {},
    length(local.kafka_secret_properties_effective) > 0 ? {
      connections = {
        (var.kafka.connection_name) = {
          properties = local.kafka_secret_properties_effective
        }
      }
    } : {}
  )

  helm_secrets = !local.use_chart_secrets ? null : (
    (var.security.enabled || length(local.kafka_secret_properties_effective) > 0) ? merge(
      var.security.enabled ? {
        micronaut = {
          security = {
            token = {
              jwt = {
                signatures = {
                  secret = {
                    generator = {
                      secret = local.micronaut_jwt_secret
                    }
                  }
                }
              }
            }
          }
        }
      } : {},
      length(local.akhq_secret_block) > 0 ? { akhq = local.akhq_secret_block } : {}
    ) : null
  )

  ingress_enabled = try(var.ingress.enabled, true)
  ingress_values = local.ingress_enabled ? {
    enabled          = true
    ingressClassName = try(var.ingress.ingress_class_name, "")
    annotations      = try(var.ingress.annotations, {})
    labels           = {}
    paths            = [try(var.ingress.path, "/")]
    pathType         = try(var.ingress.path_type, "Prefix")
    hosts            = [var.hostname]
    tls              = try(var.ingress.tls, [])
    } : {
    enabled          = false
    ingressClassName = ""
    annotations      = {}
    labels           = {}
    paths            = ["/"]
    pathType         = "ImplementationSpecific"
    hosts            = []
    tls              = []
  }

  helm_values = merge(
    {
      replicaCount  = var.replicas
      networkPolicy = { enabled = var.network_policy_enabled }
      configuration = local.configuration
      ingress       = local.ingress_values
    },
    local.helm_secrets != null ? { secrets = local.helm_secrets } : {},
    !local.use_chart_secrets ? { existingSecrets = var.existing_secrets } : {},
    length(local.normalized_resources) > 0 ? { resources = local.normalized_resources } : {},
    length(var.pod_labels) > 0 ? { podLabels = var.pod_labels } : {}
  )
}

resource "random_password" "micronaut_jwt" {
  count = local.generate_jwt ? 1 : 0

  length  = 48
  special = false
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
  repository       = "https://akhq.io/"
  chart            = "akhq"
  namespace        = var.namespace
  version          = var.chart_version
  create_namespace = false

  atomic          = true
  cleanup_on_fail = true
  wait            = true
  timeout         = var.helm_timeout

  values = [
    yamlencode(local.helm_values),
  ]

  lifecycle {
    precondition {
      condition = !var.security.enabled || !local.use_chart_secrets || (
        var.security.basic_auth_password != null && var.security.basic_auth_password != ""
      )
      error_message = "When security.enabled and the module manages secrets, set security.basic_auth_password (or disable security, or supply existing_secrets)."
    }
  }
}
