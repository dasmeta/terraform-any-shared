# Gateway API CRDs should be installed first before any Istio components
module "gateway_api_crds" {
  count  = try(var.configs.gateway.crds.enabled, true) ? 1 : 0
  source = "../gateway-api-crds"
}

resource "helm_release" "istio_base" {
  count = var.configs.base.enabled ? 1 : 0

  name             = var.configs.base.name
  repository       = coalesce(try(var.configs.base.repository, null), var.configs.chart.repository)
  chart            = var.configs.base.chart
  namespace        = var.configs.chart.namespace
  version          = coalesce(try(var.configs.base.version, null), var.configs.chart.version)
  create_namespace = var.configs.chart.create_namespace
  atomic           = var.configs.chart.atomic
  wait             = var.configs.chart.wait
  timeout          = var.configs.chart.timeout

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
  repository       = coalesce(try(var.configs.istiod.repository, null), var.configs.chart.repository)
  chart            = var.configs.istiod.chart
  namespace        = var.configs.chart.namespace
  version          = coalesce(try(var.configs.istiod.version, null), var.configs.chart.version)
  create_namespace = var.configs.chart.create_namespace
  atomic           = var.configs.chart.atomic
  wait             = var.configs.chart.wait
  timeout          = var.configs.chart.timeout

  values = [
    jsonencode(local.global_image_values),
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
  for_each = {
    for gateway in var.configs.gateway.ingress_gateways : gateway.name => gateway
  }

  name             = each.value.name
  repository       = coalesce(try(each.value.repository, null), var.configs.chart.repository)
  chart            = each.value.chart
  namespace        = var.configs.chart.namespace
  version          = coalesce(try(each.value.version, null), var.configs.chart.version)
  create_namespace = var.configs.chart.create_namespace
  atomic           = var.configs.chart.atomic
  wait             = var.configs.chart.wait
  timeout          = var.configs.chart.timeout

  values = [
    jsonencode(try(each.value.configs, {})),
    jsonencode(try(each.value.extra_configs, {})),
  ]

  depends_on = [
    helm_release.istiod,
  ]
}

# Creates a Kubernetes IngressClass resource that allows Kubernetes Ingress resources to use Istio's ingress gateway.
# This IngressClass enables routing traffic through Istio's ingress gateway when using standard Kubernetes Ingress resources.
resource "kubectl_manifest" "istio_ingress_class" {
  for_each = {
    for gateway in var.configs.gateway.ingress_gateways : gateway.name => gateway
    if try(gateway.ingress_class.create, true)
  }

  yaml_body = <<-YAML
    apiVersion: networking.k8s.io/v1
    kind: IngressClass
    metadata:
      name: ${each.value.ingress_class.name}
    spec:
      controller: istio.io/ingress-controller
  YAML
}

# Creates Kubernetes native Gateway API resources (Gateway) using the gateway-api helm chart.
# These resources work with Istio when Gateway API CRDs are installed and istiod is running.
# This is the recommended approach for managing ingress traffic when using Istio with native Gateway API.
resource "helm_release" "gateway_api_resources" {
  count = try(var.configs.gateway.api_resources.enabled, true) ? 1 : 0

  name       = var.configs.gateway.api_resources.name
  chart      = var.configs.gateway.api_resources.chart
  repository = var.configs.gateway.api_resources.chart_repository
  version    = var.configs.gateway.api_resources.chart_version
  namespace  = var.configs.chart.namespace
  atomic     = var.configs.chart.atomic
  wait       = var.configs.chart.wait
  timeout    = var.configs.chart.timeout

  values = [
    jsonencode(merge(
      { enabled = true },
      {
        gateways   = try(var.configs.gateway.api_resources.gateways, [])
        httpRoutes = try(var.configs.gateway.api_resources.httpRoutes, [])
        grpcRoutes = try(var.configs.gateway.api_resources.grpcRoutes, [])
        tcpRoutes  = try(var.configs.gateway.api_resources.tcpRoutes, [])
        tlsRoutes  = try(var.configs.gateway.api_resources.tlsRoutes, [])
        udpRoutes  = try(var.configs.gateway.api_resources.udpRoutes, [])
        istio      = try(var.configs.gateway.api_resources.istio, {})
      }
    )),
  ]

  depends_on = [
    module.gateway_api_crds,
    helm_release.istiod,
  ]
}

module "kiali" {
  count = try(var.configs.kiali.enabled, false) ? 1 : 0

  source = "../kiali"
  configs = merge(
    var.configs.kiali,
    {
      operator = merge(
        try(var.configs.kiali.operator, {}),
        {
          namespace     = coalesce(try(var.configs.kiali.operator.namespace, null), var.configs.chart.namespace)
          chart_version = var.configs.kiali.operator.chart_version
          image = merge(
            try(var.configs.kiali.operator.image.tag, null) != null ? { tag = var.configs.kiali.operator.image.tag } : {},
            local.kiali_operator_image_repo != null ? { repo = local.kiali_operator_image_repo } : {}
          )
        }
      )
      cr = merge(
        try(var.configs.kiali.cr, {}),
        {
          namespace = coalesce(try(var.configs.kiali.cr.namespace, null), var.configs.chart.namespace)
          spec = merge(
            try(var.configs.kiali.cr.spec, {}),
            {
              deployment = merge(
                try(try(var.configs.kiali.cr.spec, {}).deployment, {}),
                local.kiali_server_image_repo != null ? { image_name = local.kiali_server_image_repo } : {},
                try(var.configs.kiali.operator.image.tag, null) != null ? { image_version = var.configs.kiali.operator.image.tag } : {}
              )
            }
          )
        }
      )
    }
  )

  depends_on = [
    helm_release.istiod,
  ]
}
