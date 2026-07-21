# Example: use direct upstream Helm chart .tgz URLs instead of repository-backed
# chart names. This demonstrates the module's direct chart archive handling.

locals {
  istio_version             = "1.30.3"
  gateway_api_chart_version = "0.1.7"
  kiali_chart_version       = "2.29.0"

  chart_urls = {
    gateway_api    = "https://github.com/dasmeta/helm/releases/download/gateway-api-${local.gateway_api_chart_version}/gateway-api-${local.gateway_api_chart_version}.tgz"
    istio_base     = "https://istio-release.storage.googleapis.com/charts/base-${local.istio_version}.tgz"
    istio_istiod   = "https://istio-release.storage.googleapis.com/charts/istiod-${local.istio_version}.tgz"
    istio_gateway  = "https://istio-release.storage.googleapis.com/charts/gateway-${local.istio_version}.tgz"
    kiali_operator = "https://kiali.org/helm-charts/kiali-operator-${local.kiali_chart_version}.tgz"
  }

  istiod_global_configs = {
    proxy = {
      autoInject = "disabled"
    }
  }

  ingress_gateways = var.enable_istio_gateway_chart ? [
    {
      name  = "istio-ingressgateway"
      chart = local.chart_urls.istio_gateway
    }
  ] : []
}

module "this" {
  source = "../.."

  configs = {
    chart = {
      namespace        = "istio-system"
      create_namespace = true
      atomic           = false
      wait             = true
      timeout          = 300
    }

    base = {
      chart = local.chart_urls.istio_base
    }

    istiod = {
      chart = local.chart_urls.istio_istiod
      configs = {
        global       = local.istiod_global_configs
        autoscaleMin = 1
      }
    }

    gateway = {
      ingress_gateways = local.ingress_gateways

      api_resources = {
        chart = local.chart_urls.gateway_api
        gateways = [
          {
            name             = "docker-desktop"
            gatewayClassName = "istio"
            listeners = [
              {
                name     = "http"
                hostname = "*.localhost"
                port     = 80
                protocol = "HTTP"
                allowedRoutes = {
                  namespaces = {
                    from = "All"
                  }
                }
              }
            ]
          }
        ]
      }
    }

    kiali = {
      enabled = var.enable_kiali
      operator = {
        chart = local.chart_urls.kiali_operator
      }
      cr = {
        external_services = {
          prometheus = {
            url = "http://prometheus.monitoring:9090/"
          }
          grafana = {
            enabled      = false
            internal_url = "http://grafana.monitoring:3000/"
          }
        }
      }
    }
  }
}

resource "helm_release" "http_echo" {
  name             = "http-echo"
  repository       = "https://dasmeta.github.io/helm"
  chart            = "base"
  version          = "0.3.29"
  namespace        = "localhost"
  create_namespace = true
  wait             = true

  values = [
    file("${path.module}/http-echo.yaml")
  ]

  depends_on = [module.this]
}
