resource "helm_release" "this" {
  name             = var.name
  repository       = "https://kyverno.github.io/kyverno/"
  chart            = "kyverno"
  namespace        = var.namespace
  version          = var.chart_version
  create_namespace = var.create_namespace
  atomic           = var.atomic
  wait             = var.wait

  values = [jsonencode(module.custom_default_configs.merged)]
}

resource "helm_release" "resources" {
  name       = "${var.name}-resources"
  repository = "https://dasmeta.github.io/helm"
  chart      = "resource"
  namespace  = var.namespace
  version    = var.resource_chart_version
  atomic     = var.atomic
  wait       = var.wait

  values = [jsonencode({ resources = local.policies })]

  depends_on = [helm_release.this]
}

module "custom_default_configs" {
  source  = "cloudposse/config/yaml//modules/deepmerge"
  version = "1.0.2"

  maps = [
    var.default_configs,
    var.extra_configs
  ]
}
