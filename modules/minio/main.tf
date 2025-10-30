resource "helm_release" "minio" {
  name             = var.name
  repository       = "https://charts.min.io/"
  chart            = "minio"
  namespace        = var.namespace
  version          = var.chart_version
  create_namespace = var.create_namespace
  atomic           = var.atomic
  wait             = var.wait

  values = [jsonencode(module.custom_default_configs.merged)]
}

module "custom_default_configs" {
  source  = "cloudposse/config/yaml//modules/deepmerge"
  version = "1.0.2"

  maps = [
    var.default_configs,
    var.extra_configs
  ]
}
