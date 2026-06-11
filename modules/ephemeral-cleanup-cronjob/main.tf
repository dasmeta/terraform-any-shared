resource "helm_release" "this" {
  name             = var.release_name
  repository       = var.chart_repository
  chart            = var.chart_name
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = var.create_namespace
  wait             = var.wait
  atomic           = var.atomic
  timeout          = var.timeout

  values = [
    yamlencode(local.helm_values)
  ]
}
