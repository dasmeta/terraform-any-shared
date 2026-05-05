# Kubeconfig used by Helm/Kubernetes providers.
#
# Default: ~/.kube/config
#
# Verify:
#   kubectl --kubeconfig=<path> config view --minify -o jsonpath='{.clusters[0].cluster.server}{"\n"}'

terraform {
  required_version = "~> 1.3"

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

provider "helm" {}

provider "kubernetes" {}
