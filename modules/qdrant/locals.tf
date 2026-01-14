locals {
  # Module defaults
  default_values = {
    replicaCount = 1

    service = {
      type = "ClusterIP"
    }

    persistence = {
      enabled = true
      size    = "20Gi"
    }

    resources = {}

    ingress = {
      enabled     = false
      annotations = {}
      hosts       = []
    }
  }

  # ✅ Terraform-supported merge (shallow, deterministic)
  helm_values = merge(
    local.default_values,
    var.config
  )
}
