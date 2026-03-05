resource "helm_release" "this" {
  name             = var.name
  repository       = "https://docs.renovatebot.com/helm-charts"
  chart            = "renovate"
  namespace        = var.namespace
  version          = var.chart_version
  create_namespace = var.create_namespace
  atomic           = var.atomic
  wait             = var.wait

  values = [
    jsonencode(local.default_helm_values),
    jsonencode(var.custom_configs),
  ]
}
