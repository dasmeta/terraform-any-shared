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
      # Enable Gateway API resources (native k8s Gateway objects)
      items = [
        {
          name             = "main"
          gatewayClassName = "istio"
          listeners = [
            {
              name     = "domain1"
              hostname = "http-echo-gateway-api.localhost"
              port     = 80
              protocol = "HTTP"
              allowedRoutes = {
                namespaces = {
                  from = "All"
                }
              }
            },
            {
              name     = "domain2"
              port     = 80
              protocol = "HTTP"
              hostname = "http-echo-route-only.localhost"
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
          }
        }
      }
    }
  }
}
