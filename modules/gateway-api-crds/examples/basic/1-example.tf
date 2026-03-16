# Example: Install Gateway API CRDs
#
# This configuration installs the Kubernetes Gateway API CRDs from the official
# Gateway API repository. These CRDs are required before installing any Gateway
# API controller (e.g., Istio Gateway API controller, NGINX Gateway, etc.)

module "this" {
  source = "../.."
}
