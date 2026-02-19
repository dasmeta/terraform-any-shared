terraform {
  required_version = "~> 1.3"

  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
  }
}

## to run the example set kubectl provider env variables to connect to existing k8s setup by running the following commands(replace `/path/to/your/k8s.kubeconfig` with your k8s cluster kubeconfig path)
# `export KUBECONFIG=/path/to/your/k8s.kubeconfig`
provider "kubectl" {}
provider "http" {}
