resource "helm_release" "service" {
  name       = var.name
  namespace  = var.namespace
  repository = "https://dasmeta.github.io/helm/"
  chart      = "base"

  values = [
    yamlencode(var.helm_values)
  ]
}
