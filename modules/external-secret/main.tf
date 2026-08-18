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
    spec = merge(
      {
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
      },
      # Full sync (sync_all = true): extract EVERY property from the remote key into the
      # target Secret via spec.dataFrom[].extract.
      var.sync_all ? {
        dataFrom = [
          {
            extract = {
              key = var.remote_key
            }
          }
        ]
      } : {},
      # List sync (sync_all = false, default): explicit per-property mappings via spec.data[].
      var.sync_all ? {} : {
        data = [
          for mapping in var.mappings : {
            secretKey = mapping.secret_key
            remoteRef = {
              key      = var.remote_key
              property = mapping.remote_property
            }
          }
        ]
      },
    )
  })

  lifecycle {
    precondition {
      condition     = var.sync_all ? length(var.mappings) == 0 : length(var.mappings) > 0
      error_message = "Provide one or more mappings for explicit list sync (sync_all = false), or set sync_all = true to extract all properties from remote_key (mappings must then be empty)."
    }
  }
}
