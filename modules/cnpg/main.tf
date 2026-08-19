resource "kubectl_manifest" "cluster" {
  # kubectl_manifest.wait handles deletion finalization only. Consumers must
  # explicitly wait for CNPG's Ready condition before deploying workloads.
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
        inheritedMetadata = {
          labels      = var.labels
          annotations = var.annotations
        }
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
            var.postgresql_parameters,
            { password_encryption = "scram-sha-256" }, # pragma: allowlist secret
          )
        }
      },
      (length(var.resources.limits) > 0 || length(var.resources.requests) > 0) ? { resources = var.resources } : {},
    )
  })
}
