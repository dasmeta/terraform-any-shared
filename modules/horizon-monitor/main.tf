# Helm release for the application
resource "helm_release" "this" {
  name       = var.name
  namespace  = var.namespace
  repository = var.repository
  chart      = var.chart
  version    = var.chart_version

  create_namespace = var.create_namespace

  values = [
    yamlencode({
      # Image configuration
      image = {
        repository = var.image.repository
        tag        = var.image.tag
        pullPolicy = var.image.pullPolicy
      }

      # Container port
      containerPort = var.container_port

      # Ingress configuration
      ingress = {
        enabled     = var.ingress.enabled
        class       = var.ingress.class
        annotations = var.ingress.annotations
        hosts       = var.ingress.hosts
        tls         = var.ingress.tls
      }

      # Resource limits and requests
      resources = var.resources

      # Environment variables
      config = var.config


      # Storage configuration
      storage = var.storage
      volumes = var.volumes

      # Health checks
      livenessProbe  = var.liveness_probe
      readinessProbe = var.readiness_probe
      startupProbe   = var.startup_probe

      # Node selection
      nodeSelector = var.node_selector
      tolerations  = var.tolerations
      affinity     = var.affinity

      # Service account
      serviceAccount = {
        create      = var.service_account.create
        name        = var.service_account.name
        annotations = var.service_account.annotations
      }

      # Product and environment
      product = var.product
      env     = var.env

      # Labels
      labels = var.labels
    })
  ]
}
