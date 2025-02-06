resource "helm_release" "service" {
  name       = var.name
  namespace  = var.namespace
  repository = var.repository
  chart      = var.chart

  values = [
    yamlencode(var.helm_values)
  ]
}
