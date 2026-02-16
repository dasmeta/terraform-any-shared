locals {
  istio_repository = var.configs.repository
  istio_namespace  = var.configs.namespace

  istio_create_namespace = var.configs.create_namespace
  istio_atomic           = var.configs.atomic
  istio_wait             = var.configs.wait
}

# Gateway API CRDs should be installed first before any Istio components
module "gateway_api_crds" {
  count  = try(var.configs.gateway.crds.enabled, true) ? 1 : 0
  source = "../gateway-api-crds"

  crd_version = try(var.configs.gateway.crds.version, "v1.4.1")
}

resource "helm_release" "istio_base" {
  count = var.configs.base.enabled ? 1 : 0

  name             = var.configs.base.name
  repository       = local.istio_repository
  chart            = "base"
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

# istio-gateway helm chart: Only needed when using Istio's custom Gateway API implementation (VirtualService, Gateway CRDs).
# When using Kubernetes native Gateway API resources (gateway.networking.k8s.io), this helm chart is NOT required
# and should be disabled. The gateway is then managed through Kubernetes Gateway resources instead.
# Additionally, this helm chart is also used for Istio ingress creation and management, providing the ingress gateway
# service that can be used with Kubernetes Ingress resources (via IngressClass) to route traffic into the Istio service mesh.
resource "helm_release" "gateway" {
  count = try(var.configs.gateway.ingressgateway.enabled, false) ? 1 : 0

  name             = try(var.configs.gateway.ingressgateway.name, "istio-ingressgateway")
  repository       = local.istio_repository
  chart            = "gateway"
  namespace        = local.istio_namespace
  version          = try(var.configs.gateway.ingressgateway.chart_version, "1.28.3")
  create_namespace = local.istio_create_namespace
  atomic           = local.istio_atomic
  wait             = local.istio_wait

  values = [
    jsonencode(try(var.configs.gateway.ingressgateway.configs, {})),
    jsonencode(try(var.configs.gateway.ingressgateway.extra_configs, {})),
  ]

  depends_on = [
    helm_release.istiod,
  ]
}

# Creates a Kubernetes IngressClass resource that allows Kubernetes Ingress resources to use Istio's ingress gateway.
# This IngressClass enables routing traffic through Istio's ingress gateway when using standard Kubernetes Ingress resources.
resource "kubectl_manifest" "istio_ingress_class" {
  count = try(var.configs.gateway.ingressgateway.enabled, false) && try(var.configs.gateway.ingressgateway.ingress_class.create, true) ? 1 : 0

  yaml_body = <<-YAML
    apiVersion: networking.k8s.io/v1
    kind: IngressClass
    metadata:
      name: ${try(var.configs.gateway.ingressgateway.ingress_class.name, "istio")}
    spec:
      controller: istio.io/ingress-controller
  YAML
}

# Creates Kubernetes native Gateway API resources (Gateway) using the gateway-api helm chart.
# These resources work with Istio when Gateway API CRDs are installed and istiod is running.
# This is the recommended approach for managing ingress traffic when using Istio with native Gateway API.
resource "helm_release" "gateway_api_resources" {
  count = length(try(var.configs.gateway.items, [])) > 0 ? 1 : 0

  name      = "gateway-api-resources"
  chart     = "/Users/tmuradyan/projects/dasmeta/helm/charts/gateway-api"
  namespace = local.istio_namespace
  atomic    = local.istio_atomic
  wait      = local.istio_wait

  values = [
    jsonencode({
      enabled  = true
      gateways = var.configs.gateway.items
    }),
  ]

  depends_on = [
    module.gateway_api_crds,
    helm_release.istiod,
  ]
}
