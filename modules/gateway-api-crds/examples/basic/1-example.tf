# Example: Install Gateway API CRDs
#
# This configuration installs the Kubernetes Gateway API CRDs from the official
# Gateway API repository. These CRDs are required before installing any Gateway
# API controller (e.g., Istio Gateway API controller, NGINX Gateway, etc.)

module "gateway_api_crds" {
  source = "../.."

  # Use the latest stable version (default: v1.4.1)
  # crd_version = "v1.4.1"
}
