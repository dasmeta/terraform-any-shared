resource "helm_release" "this" {
  name             = var.name
  repository       = "https://sentry-kubernetes.github.io/charts"
  chart            = "sentry"
  namespace        = var.namespace
  version          = var.chart_version
  create_namespace = var.create_namespace
  atomic           = var.atomic
  wait             = var.wait
  timeout          = 1800

  values = [jsonencode(module.custom_default_configs.merged)]
}

module "minio" {
  count  = var.minio_configs.enabled ? 1 : 0
  source = "../minio"

  extra_configs = var.minio_configs.extra_configs
  name          = var.minio_configs.name
  namespace     = var.namespace
  chart_version = var.minio_configs.chart_version
}

module "custom_default_configs" {
  source  = "cloudposse/config/yaml//modules/deepmerge"
  version = "1.0.2"

  maps = [
    var.default_configs,
    var.extra_configs
  ]
}
