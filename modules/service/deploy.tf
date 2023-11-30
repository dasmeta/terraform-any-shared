resource "helm_release" "service" {
  name      = var.name
  namespace = var.namespace
  chart     = "dasmeta/base"

  values = [
    yamlencode(var.helm_values)
  ]
}
