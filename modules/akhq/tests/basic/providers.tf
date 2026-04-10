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
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

locals {
  kubeconfig = var.kubeconfig_path != "" ? var.kubeconfig_path : pathexpand("~/.kube/config")
}

provider "helm" {
  kubernetes {
    config_path = local.kubeconfig
  }
}

provider "kubernetes" {
  config_path = local.kubeconfig
}

provider "random" {}
