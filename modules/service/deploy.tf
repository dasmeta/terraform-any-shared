resource "helm_release" "marketplace_services" {
  name      = var.name
  namespace = var.namespace
  chart     = "dasmeta/base"

  values = [
    yamlencode(var.helm_values)
  ]
}
