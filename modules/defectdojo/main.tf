# locals {
#   helm_values = merge(var.default_configs, var.custom_configs)
# }

resource "helm_release" "this" {
  name             = var.name
  repository       = "https://raw.githubusercontent.com/DefectDojo/django-DefectDojo/helm-charts"
  chart            = "defectdojo"
  namespace        = var.namespace
  version          = var.chart_version
  create_namespace = var.create_namespace
  atomic           = var.atomic
  wait             = var.wait

  values = [
    jsonencode(var.default_configs),
    jsonencode(var.custom_configs),
  ]
}
