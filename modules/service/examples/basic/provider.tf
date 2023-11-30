## This file and its content are generated based on config, pleas check README.md for more details
provider "aws" {
  region = "us-east-1"
}

provider "kubernetes" {
  cluster_ca_certificate = "cluster_ca_certificate"
  host                   = "host"

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args = [
      "eks",
      "--region",
      "eu-central-1",
      "get-token",
      "--cluster-name",
    "dev"]
    command = "aws"
  }
}

provider "helm" {
  kubernetes {
    cluster_ca_certificate = "cluster_ca_certificate"
    host                   = "host"
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args = [
        "eks",
        "--region",
        "us-east-1",
        "get-token",
        "--cluster-name",
        "eks-dev"
      ]
      command = "aws"
    }
  }
}
