## This file and its content are generated based on config, pleas check README.md for more details

terraform {

  required_providers {

    aws = {
      source                = "hashicorp/aws"
      version               = "~> 5.0"
      configuration_aliases = []
    }

    helm = {
      source                = "hashicorp/helm"
      version               = "~> 2.5"
      configuration_aliases = []
    }

    kubernetes = {
      source                = "hashicorp/kubernetes"
      version               = "~> 2.23"
      configuration_aliases = []
    }

  }

  required_version = ">= 1.3.0"
}
