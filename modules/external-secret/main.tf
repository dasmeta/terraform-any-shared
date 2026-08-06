resource "kubectl_manifest" "external_secret" {
  server_side_apply = true

  yaml_body = yamlencode({
    apiVersion = "external-secrets.io/v1"
    kind       = "ExternalSecret"
    metadata = {
      name        = var.name
      namespace   = var.namespace
      labels      = var.labels
      annotations = var.annotations
    }
    spec = {
      refreshPolicy   = "Periodic"
      refreshInterval = var.refresh_interval
      secretStoreRef = {
        name = var.secret_store.name
        kind = var.secret_store.kind
      }
      target = {
        name           = var.target.name
        creationPolicy = var.target.creation_policy
        deletionPolicy = var.target.deletion_policy
        template = {
          type = var.target.type
        }
      }
      data = [
        for mapping in var.mappings : {
          secretKey = mapping.secret_key
          remoteRef = {
            key      = var.remote_key
            property = mapping.remote_property
          }
        }
      ]
    }
  })
}
