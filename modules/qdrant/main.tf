resource "kubernetes_namespace" "this" {
  count = var.create_namespace ? 1 : 0
  metadata { name = var.namespace }
}

resource "helm_release" "qdrant" {
  name       = var.name
  namespace  = var.namespace
  repository = var.chart_repo
  chart      = var.chart_name
  version    = var.chart_version != "" ? var.chart_version : null

  atomic          = true
  cleanup_on_fail = true

  values = [
    yamlencode(local.helm_values)
  ]

  depends_on = [kubernetes_namespace.this]
}
