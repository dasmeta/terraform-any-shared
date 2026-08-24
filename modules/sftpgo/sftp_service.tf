resource "kubernetes_service_v1" "sftp" {
  count = var.sftp_service.enabled ? 1 : 0

  metadata {
    name      = "${var.name}-sftp"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/instance"   = var.name
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/name"       = "sftpgo"
    }
    annotations = var.sftp_service.annotations
  }

  spec {
    type                        = var.sftp_service.type
    load_balancer_class         = var.sftp_service.type == "LoadBalancer" ? var.sftp_service.load_balancer_class : null
    load_balancer_source_ranges = coalesce(var.sftp_service.load_balancer_source_ranges, [])

    selector = {
      "app.kubernetes.io/instance" = var.name
      "app.kubernetes.io/name"     = "sftpgo"
    }

    port {
      name        = "sftp"
      port        = var.sftp_service.port
      target_port = "sftp"
      protocol    = "TCP"
    }
  }

  depends_on = [helm_release.this]
}
