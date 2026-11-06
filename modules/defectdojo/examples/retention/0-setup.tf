terraform {
  required_version = "~> 1.3"
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

variable "engagement_names" {
  type        = set(string)
  description = "Exact unique names of engagements with retired feature Tests eligible for retention."
}

locals {
  release_name = "example-defectdojo"
}
