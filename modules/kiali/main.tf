locals {
  kiali_operator_chart_is_url = can(regex("^https?://", var.configs.operator.chart))
}

resource "helm_release" "operator" {
  count = local.kiali_operator_enabled ? 1 : 0

  name             = var.configs.operator.name
  repository       = local.kiali_operator_chart_is_url ? null : var.configs.operator.chart_repository
  chart            = var.configs.operator.chart
  namespace        = var.configs.operator.namespace
  version          = local.kiali_operator_chart_is_url ? null : var.configs.operator.chart_version
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
        var.configs.operator.image.repo != null ||
        var.configs.operator.image.tag != null ||
        var.configs.operator.image.digest != null
        ) ? {
        image = merge(
          var.configs.operator.image.repo != null ? { repo = var.configs.operator.image.repo } : {},
          var.configs.operator.image.tag != null ? { tag = var.configs.operator.image.tag } : {},
          var.configs.operator.image.digest != null ? { digest = var.configs.operator.image.digest } : {}
        )
      } : {},
      (
        try(local.kiali_cr_spec.deployment.image_name, null) != null ||
        try(local.kiali_cr_spec.deployment.image_version, null) != null
        ) ? {
        # Auto-enable ad-hoc image support when Kiali CR uses custom server image fields.
        allowAdHocKialiImage = true
      } : {},
      var.configs.operator.values
    )),
    jsonencode(var.configs.operator.extra_values),
  ]
}

resource "kubectl_manifest" "this" {
  count = local.kiali_cr_enabled ? 1 : 0

  wait = true

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
