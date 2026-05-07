# Example: explicitly pass chart/image overrides using current defaults.
# This example shows where to set custom values for all Istio components and
# gateway-api chart while keeping behavior equal to defaults.

module "this" {
  source = "../.."

  configs = {
    # helm chart override settings for base/istiod/gateway istio components.
    chart = {
      repository       = "https://istio-release.storage.googleapis.com/charts"
      version          = "1.29.2"
      namespace        = "istio-system"
      create_namespace = true
      atomic           = false
      wait             = true
      timeout          = 300
    }
    # image override settings used by Istio components and gateways-api gateways
    image = {
      registry  = "docker.io"
      namespace = "istio"
      tag       = "1.29.2"
      repository = {
        istiod = "pilot"
        proxy  = "proxyv2"
      }
    }

    gateway = {
      ingress_gateways = [
        {
          name = "istio-ingressgateway"
        }
      ]

      # Custom gateway-api chart version override.
      api_resources = {
        chart_version    = "0.1.7"
        chart_repository = "https://dasmeta.github.io/helm"
        gateways = [
          {
            name      = "main"
            listeners = [{ port = 80, protocol = "HTTP" }]
          }
        ]
      }
    }

    # Kiali overrides shown in the same example to demonstrate
    # combined Istio chart/image and Kiali customization flow.
    kiali = {
      enabled = true
      operator = {
        chart_repository = "https://kiali.org/helm-charts"
        chart_version    = "2.25.0"
        image = {
          registry  = "quay.io"
          namespace = "kiali"
          tag       = "v2.25.0"
          repository = {
            operator = "kiali-operator"
            server   = "kiali"
          }
        }
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
