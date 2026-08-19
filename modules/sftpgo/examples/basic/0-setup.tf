terraform {
  required_version = "~> 1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }
}

variable "region" {
  type        = string
  default     = "eu-central-1"
  description = "AWS region used by the EKS cluster and S3 bucket."
}

variable "cluster_name" {
  type        = string
  default     = "eks-dev"
  description = "EKS cluster name used by provider exec authentication."
}

variable "cluster_ca_certificate" {
  type        = string
  description = "Base64-encoded EKS cluster CA certificate."
}

variable "cluster_host" {
  type        = string
  description = "EKS cluster API endpoint."
}

variable "aws_access_key" {
  type        = string
  description = "AWS access key for the example provider."
  sensitive   = true
}

variable "aws_secret_key" {
  type        = string
  description = "AWS secret key for the example provider."
  sensitive   = true
}

variable "sftpgo_s3_access_key" {
  type        = string
  description = "S3 access key used by SFTPGo bootstrap users."
  sensitive   = true
}

variable "sftpgo_s3_access_secret" {
  type        = string
  description = "S3 access secret used by SFTPGo bootstrap users."
  sensitive   = true
}

variable "sftpgo_admin_password" {
  type        = string
  description = "Initial SFTPGo admin password."
  sensitive   = true
}

variable "sftpgo_web_session_signing_passphrase" {
  type        = string
  description = "Stable signing passphrase for SFTPGo WebAdmin and WebClient sessions."
  sensitive   = true
}

variable "sftpgo_demo_user_password" {
  type        = string
  description = "Bootstrap password for the demo SFTPGo user."
  sensitive   = true
}

provider "aws" {
  region     = var.region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key

  default_tags {
    tags = {
      Account     = "example-dev"
      ManageLevel = "environment"
    }
  }
}

provider "kubernetes" {
  host                   = var.cluster_host
  cluster_ca_certificate = base64decode(var.cluster_ca_certificate)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args = [
      "eks",
      "--region",
      var.region,
      "get-token",
      "--cluster-name",
      var.cluster_name,
    ]
    command = "aws"
  }
}

provider "helm" {
  kubernetes {
    host                   = var.cluster_host
    cluster_ca_certificate = base64decode(var.cluster_ca_certificate)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args = [
        "eks",
        "--region",
        var.region,
        "get-token",
        "--cluster-name",
        var.cluster_name,
      ]
      command = "aws"
    }
  }
}
