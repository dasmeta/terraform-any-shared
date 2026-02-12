# Example: Istio configured for Gateway API (vertical routing) only
# with horizontal service mesh routing (sidecar injection) disabled
#
# This configuration:
# - Installs Istio with Gateway API CRDs (enabled by default)
# - Disables automatic sidecar injection (horizontal service mesh)
# - Enables Istio Gateway API controller for vertical routing (ingress-like)
# - Uses Istio Gateway resources for traffic ingress/egress only

module "this" {
  source = "../.."

  configs = {
    # Istiod configuration - disable automatic sidecar injection
    istiod = {
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
