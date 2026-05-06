resource "helm_release" "operator" {
  count = local.kiali_operator_enabled ? 1 : 0

  name             = var.configs.operator.name
  repository       = var.chart_repository
  chart            = var.configs.operator.chart
  namespace        = var.configs.operator.namespace
  version          = var.configs.operator.chart_version
  create_namespace = var.configs.operator.create_namespace
  atomic           = var.configs.operator.atomic
  wait             = var.configs.operator.wait

  values = [
    jsonencode(merge(
      {
        cr = {
          create = false
        }
      },
      (
        var.image.repo != null ||
        var.image.tag != null ||
        var.image.digest != null ||
        var.image.allow_ad_hoc_kiali_image != null
      ) ? { image = var.image } : {},
      var.configs.operator.values
    )),
    jsonencode(var.configs.operator.extra_values),
  ]
}

resource "kubectl_manifest" "this" {
  count = local.kiali_cr_enabled ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "kiali.io/v1alpha1"
    kind       = "Kiali"
    metadata = {
      name        = var.configs.cr.name
      namespace   = var.configs.cr.namespace
      labels      = var.configs.cr.labels
      annotations = var.configs.cr.annotations
    }
    spec = local.kiali_cr_spec
  })

  depends_on = [
    helm_release.operator,
  ]
}
