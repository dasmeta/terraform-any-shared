resource "helm_release" "service" {
  name       = var.name
  namespace  = var.namespace
  repository = "https://dasmeta.github.io/helm/"
  chart      = "dasmeta/base"

  values = [
    yamlencode(var.helm_values)
  ]
}
