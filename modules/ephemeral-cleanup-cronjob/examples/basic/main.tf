terraform {
  required_version = "~> 1.3"

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13"
    }
  }
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

module "ephemeral_helm_cleanup" {
  source = "../.."

  namespace              = "staging"
  schedule               = "0 2 * * *"
  namespace_name_pattern = "ephemeral"
}
