resource "helm_release" "qdrant" {
  name             = var.name
  namespace        = var.namespace
  repository       = var.chart_repo
  chart            = var.chart_name
  version          = var.chart_version
  create_namespace = var.create_namespace

  atomic          = true
  cleanup_on_fail = true

  values = [
    yamlencode(local.default_values),
    yamlencode(var.config),
  ]
}
