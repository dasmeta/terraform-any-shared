# Example: Install Gateway API CRDs
#
# This configuration installs the Kubernetes Gateway API CRDs pulled from the official
# Gateway API repository. These CRDs are required before installing/using any Gateway
# API controller (e.g., Istio Gateway API controller)

module "this" {
  source  = "../.."
  configs = var.configs
}
