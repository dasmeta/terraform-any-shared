resource "helm_release" "this" {
  name             = var.name
  repository       = var.chart_repository
  chart            = var.chart
  namespace        = var.namespace
  version          = var.chart_version
  create_namespace = var.create_namespace
  atomic           = var.atomic
  wait             = var.wait
  cleanup_on_fail  = var.cleanup_on_fail
  timeout          = var.timeout

  values = [
    yamlencode(local.chart_values)
  ]
}
