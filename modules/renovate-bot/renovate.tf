resource "helm_release" "renovate" {
  name      = "renovate"
  namespace = "renovate"

  repository = "https://docs.renovatebot.com/helm-charts"
  chart      = "renovate"

  values = [
    <<-EOT
        renovate:
          config: |
            {
              "platform": "${var.platform}",
              "endpoint": "${var.endpoint}",
              "token": "${var.token}",
              "autodiscover": "${var.autodiscover}",
            }
    EOT
  ]

  set {
    name  = "cronjob.schedule"
    value = var.schedule
  }
}
