locals {
  normalized_resources = merge(
    length(var.resources.limits) > 0 ? { limits = var.resources.limits } : {},
    length(var.resources.requests) > 0 ? { requests = var.resources.requests } : {},
  )

  backup_barman_object_store = var.backup == null ? null : merge(
    {
      destinationPath = var.backup.destination_path
      serverName      = var.name
      s3Credentials = merge(
        {
          accessKeyId = {
            name = var.backup.credentials_secret_name
            key  = var.backup.access_key_id_key
          }
          secretAccessKey = {
            name = var.backup.credentials_secret_name
            key  = var.backup.secret_access_key_key
          }
        },
        var.backup.region_key != null ? {
          region = {
            name = var.backup.credentials_secret_name
            key  = var.backup.region_key
          }
        } : {},
        var.backup.session_token_key != null ? {
          sessionToken = {
            name = var.backup.credentials_secret_name
            key  = var.backup.session_token_key
          }
        } : {},
      )
      data = {
        compression = "gzip"
      }
      wal = {
        compression = "gzip"
      }
    },
    var.backup.endpoint_url != null ? { endpointURL = var.backup.endpoint_url } : {},
  )

  backup_spec = var.backup == null ? {} : {
    backup = {
      barmanObjectStore = local.backup_barman_object_store
      retentionPolicy   = var.backup.retention_policy
      target            = "prefer-standby"
    }
  }
}
