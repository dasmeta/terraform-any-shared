variable "name" {
  description = "The name of helm release."
  type        = string
  default     = "minio"
}

variable "chart_version" {
  type        = string
  default     = "17.0.21"
  description = "The app chart version to use"
}

variable "namespace" {
  description = "The namespace to install app helm. The doc recommends to have kyverno installed in its own namespace so before changing this check docs."
  type        = string
  default     = "minio"
}

variable "create_namespace" {
  type        = bool
  default     = true
  description = "Create namespace if requested"
}

variable "wait" {
  type        = bool
  default     = true
  description = "Whether wait to get the workload run successfully"
}

variable "atomic" {
  type        = bool
  default     = false
  description = "Whether auto rollback if helm install fails"
}

variable "default_configs" {
  type = any
  default = {
    image = {
      repository = "bitnamilegacy/minio"
    }
    console = {
      image = {
        repository = "bitnamilegacy/minio-object-browser"
      }
    }
    accessKey = {
      password = "sentry"
    }
    defaultBuckets = "sentry"
    persistence = {
      enabled = true
      size    = "50Gi"
    }
    replicas = 3
    resources = {
      requests = {
        cpu    = "300m"
        memory = "512Mi"
      }
      limits = {
        cpu    = "600m"
        memory = "1Gi"
      }
    }
  }

  description = "The default values config to pass to helm chart. NOTE: that if you need to change just one field you will need to pass all configs and that field cha changed or you can pass you custom config within var.extra_configs"
}

variable "extra_configs" {
  type        = any
  default     = {}
  description = "Configs to pass and override helm values.yaml defaults and var.default_configs if needed more fine control. for more info check https://artifacthub.io/packages/helm/kyverno/kyverno?modal=values"
}
