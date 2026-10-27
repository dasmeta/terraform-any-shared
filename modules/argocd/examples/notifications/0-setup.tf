terraform {
  required_version = "~> 1.3"

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}

# Configure the Helm provider for your cluster before plan/apply.
provider "helm" {
  kubernetes {}
}
