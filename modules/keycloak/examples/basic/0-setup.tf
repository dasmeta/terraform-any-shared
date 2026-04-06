# Meta writes the cluster context to a dedicated kubeconfig file (see meta output), e.g.
#   ~/.kube/payconomy-dev-eks-dev
# Terraform must use that same file; relying on the default client config alone can
# still hit http://localhost if ~/.kube/config is wrong.
# Verify: kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}{"\n"}'

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
