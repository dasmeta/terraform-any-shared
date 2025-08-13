resource "helm_release" "this" {
  name             = "kube-events-exporter"
  repository       = "https://dasmeta.github.io/helm"
  chart            = "kubernetes-events-exporter-enriched"
  namespace        = var.namespace
  version          = var.chart_version != "" ? var.chart_version : null
  create_namespace = var.create_namespace
  atomic           = true
  wait             = false

  values = [
    yamlencode(var.helm_values)
  ]
}
