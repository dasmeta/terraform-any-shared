locals {
  istio_repository = var.configs.repository
  istio_namespace  = var.configs.namespace

  istio_create_namespace = var.configs.create_namespace
  istio_atomic           = var.configs.atomic
  istio_wait             = var.configs.wait
}

# Gateway API CRDs should be installed first before any Istio components
module "gateway_api_crds" {
  count  = var.configs.gateway_api_crds.enabled ? 1 : 0
  source = "../gateway-api-crds"

  crd_version = var.configs.gateway_api_crds.version
}

resource "helm_release" "istio_base" {
  count = var.configs.base.enabled ? 1 : 0

  name             = var.configs.base.name
  repository       = local.istio_repository
  chart            = "istio-base"
  namespace        = local.istio_namespace
  version          = var.configs.base.chart_version
  create_namespace = local.istio_create_namespace
  atomic           = local.istio_atomic
  wait             = local.istio_wait

  values = [
    jsonencode(var.configs.base.values),
    jsonencode(var.configs.base.extra_values),
  ]

  depends_on = [
    module.gateway_api_crds,
  ]
}

resource "helm_release" "istiod" {
  count = var.configs.istiod.enabled ? 1 : 0

  name             = var.configs.istiod.name
  repository       = local.istio_repository
  chart            = "istiod"
  namespace        = local.istio_namespace
  version          = var.configs.istiod.chart_version
  create_namespace = local.istio_create_namespace
  atomic           = local.istio_atomic
  wait             = local.istio_wait

  values = [
    jsonencode(var.configs.istiod.configs),
    jsonencode(var.configs.istiod.extra_configs),
  ]

  depends_on = [
    helm_release.istio_base,
  ]
}

resource "helm_release" "gateway" {
  count = var.configs.gateway.enabled ? 1 : 0

  name             = var.configs.gateway.name
  repository       = local.istio_repository
  chart            = "gateway"
  namespace        = local.istio_namespace
  version          = var.configs.gateway.chart_version
  create_namespace = local.istio_create_namespace
  atomic           = local.istio_atomic
  wait             = local.istio_wait

  values = [
    jsonencode(var.configs.gateway.configs),
    jsonencode(var.configs.gateway.extra_configs),
  ]

  depends_on = [
    helm_release.istiod,
  ]
}
