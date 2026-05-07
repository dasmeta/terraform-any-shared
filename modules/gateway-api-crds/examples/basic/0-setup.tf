terraform {
  required_version = "~> 1.3"

  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
  }
}

## to run the example set kubectl provider env variables to connect to existing k8s setup by running the following commands(replace `/path/to/your/k8s.kubeconfig` with your k8s cluster kubeconfig path)
# `export KUBECONFIG=/path/to/your/k8s.kubeconfig`
provider "kubectl" {}

variable "configs" {
  type        = any
  default     = {}
  description = "The configs for the module. This is for the example to show the crds_keys output"
}

output "crds_keys" { # this is for the example to show the crds_keys output
  value = module.this.crds_keys
}
