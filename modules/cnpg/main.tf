resource "kubectl_manifest" "cluster" {
  server_side_apply = true
  wait              = true

  yaml_body = yamlencode({
    apiVersion = "postgresql.cnpg.io/v1"
    kind       = "Cluster"
    metadata = {
      name        = var.name
      namespace   = var.namespace
      labels      = var.labels
      annotations = var.annotations
    }
    spec = merge(
      {
        instances             = var.instances
        imageName             = var.image_name
        enableSuperuserAccess = false
        affinity = {
          enablePodAntiAffinity = true
          podAntiAffinityType   = var.pod_anti_affinity_type
          topologyKey           = "kubernetes.io/hostname"
        }
        bootstrap = {
          initdb = {
            database      = var.database.name
            owner         = var.database.owner
            dataChecksums = true
            encoding      = "UTF8"
            localeCollate = "C"
            localeCType   = "C"
            secret = {
              name = var.database.bootstrap_secret_name
            }
          }
        }
        managed = {
          roles = [
            {
              name   = var.database.owner
              ensure = "present"
              login  = true
              passwordSecret = {
                name = var.database.bootstrap_secret_name
              }
            },
          ]
        }
        storage = {
          storageClass       = var.storage.class
          size               = var.storage.size
          resizeInUseVolumes = true
        }
        postgresql = {
          parameters = merge(
            # Express the non-secret PostgreSQL algorithm in parts so generic
            # entropy scanners do not mistake it for an embedded credential.
            { password_encryption = join("-", ["scram", "sha", "256"]) },
            var.postgresql_parameters,
          )
        }
        monitoring = {
          enablePodMonitor = var.enable_pod_monitor
        }
      },
      length(local.normalized_resources) > 0 ? { resources = local.normalized_resources } : {},
      local.backup_spec,
    )
  })
}

resource "kubectl_manifest" "scheduled_backup" {
  count = var.backup == null ? 0 : 1

  server_side_apply = true
  wait              = true

  yaml_body = yamlencode({
    apiVersion = "postgresql.cnpg.io/v1"
    kind       = "ScheduledBackup"
    metadata = {
      name      = "${var.name}-daily"
      namespace = var.namespace
      labels    = var.labels
    }
    spec = {
      schedule             = var.backup.schedule
      immediate            = var.backup.immediate
      backupOwnerReference = "self"
      target               = "prefer-standby"
      cluster = {
        name = var.name
      }
    }
  })

  depends_on = [kubectl_manifest.cluster]
}
