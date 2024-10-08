resource "kubernetes_persistent_volume_claim" "this" {
  count = var.cache.type == "pvc" ? 1 : 0

  metadata {
    name      = "cache"
    namespace = var.namespace
  }
  spec {
    storage_class_name = var.cache.storage_class_name
    access_modes       = ["ReadWriteMany"]
    resources {
      requests = {
        storage = var.cache.size
      }
    }
  }
}
