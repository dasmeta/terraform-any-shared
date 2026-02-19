# Example: Istio configured for Gateway API (vertical routing) only
# with horizontal service mesh routing (sidecar injection) disabled
#
# This configuration:
# - Installs Istio with Gateway API CRDs (enabled by default via gateway.crds.enabled = true)
# - Disables automatic sidecar injection (horizontal service mesh)
# - Enables Istio Gateway API controller for vertical routing (ingress-like)
# - Uses Istio Gateway resources for traffic ingress/egress only

module "this" {
  source = "../.."

  configs = {
    # base = { enabled = false } # todo: enable this
    gateway = {
      ingressgateway = {
        enabled = false
      }
      # Enable Gateway API resources (native k8s Gateway objects)
      resources = [
        {
          name             = "main"
          gatewayClassName = "istio"
          listeners = [
            # http-echo-gateway-api.localhost
            {
              name     = "http-echo-gateway-api-http"
              hostname = "http-echo-gateway-api.localhost"
              port     = 80
              protocol = "HTTP"
              allowedRoutes = {
                namespaces = {
                  from = "All"
                }
              }
            },
            # http-echo-gw.localhost
            {
              name     = "http-echo-gw-http"
              port     = 80
              protocol = "HTTP"
              hostname = "http-echo-gw.localhost"
              allowedRoutes = {
                namespaces = {
                  from = "All"
                }
              }
            },
            # redirect-example.localhost
            {
              name     = "redirect-example"
              port     = 80
              protocol = "HTTP"
              hostname = "redirect-example.localhost"
              allowedRoutes = {
                namespaces = {
                  from = "All"
                }
              }
            },
            # forbidden-example.localhost
            {
              name     = "forbidden-example"
              port     = 80
              protocol = "HTTP"
              hostname = "forbidden-example.localhost"
              allowedRoutes = {
                namespaces = {
                  from = "All"
                }
              }
            },
            # not-found-example.localhost
            {
              name     = "not-found-example"
              port     = 80
              protocol = "HTTP"
              hostname = "not-found-example.localhost"
              allowedRoutes = {
                namespaces = {
                  from = "All"
                }
              }
            },
            # virtualservice-example.localhost
            {
              name     = "virtualservice-example"
              port     = 80
              protocol = "HTTP"
              hostname = "virtualservice-example.localhost"
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
    # Istiod configuration - disable automatic sidecar injection
    istiod = {
      # enabled = false # todo: enable this
      configs = {
        # Disable automatic sidecar injection globally
        # This prevents Istio from injecting sidecars into pods (horizontal service mesh)
        global = {
          proxy = {
            autoInject = "disabled"
            # logLevel   = "debug"
          }
        }
      }
    }
  }
}
