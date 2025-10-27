variable "name" {
  description = "Name of the application deployment"
  type        = string
  default     = "horizon"
}

variable "namespace" {
  description = "Kubernetes namespace for the deployment"
  type        = string
  default     = "horizon"
}

variable "repository" {
  description = "Helm chart repository URL"
  type        = string
  default     = "https://dasmeta.github.io/helm/"

}

variable "chart" {
  description = "Path to the base Helm chart"
  type        = string
  default     = "base"
}

# Helm chart configuration
variable "chart_version" {
  description = "Version of the base Helm chart"
  type        = string
  default     = "0.3.14"
}

variable "create_namespace" {
  description = "Whether to create the namespace if it doesn't exist"
  type        = bool
  default     = true
}

# Image configuration
variable "image" {
  description = "Container image configuration"
  type = object({
    repository = string
    tag        = string
    pullPolicy = optional(string, "IfNotPresent")
  })
  default = {
    repository = "dasmeta/horizon-monitor"
    tag        = "0.0.2"
    pullPolicy = "IfNotPresent"
  }
}

variable "container_port" {
  description = "Container port for the application"
  type        = number
  default     = 8000
}

# Ingress configuration
variable "ingress" {
  description = "Ingress configuration"
  type = object({
    enabled     = optional(bool, false)
    class       = optional(string, "nginx")
    annotations = optional(map(string), {})
    hosts = list(object({
      host = string
      paths = list(object({
        path     = string
        pathType = optional(string, "Prefix")
      }))
    }))
    tls = optional(list(object({
      hosts      = list(string)
      secretName = string
    })), [])
  })
  default = {
    enabled = false
    hosts   = []
  }
}

# Resource limits and requests
variable "resources" {
  description = "Resource limits and requests"
  type = object({
    limits = optional(object({
      cpu    = optional(string)
      memory = optional(string)
    }))
    requests = optional(object({
      cpu    = optional(string)
      memory = optional(string)
    }))
  })
  default = {
    requests = {
      cpu    = "100m"
      memory = "128Mi"
    }
    limits = {
      cpu    = "500m"
      memory = "512Mi"
    }
  }
}

# Environment variables
variable "config" {
  description = "Environment variables"
  type        = map(string)
  default     = {}
}

# Storage configuration
variable "storage" {
  description = "Persistent storage configuration"
  type = list(object({
    persistentVolumeClaimName = string
    accessModes               = list(string)
    className                 = string
    requestedSize             = string
    enableDataSource          = optional(bool, false)
  }))
  default = [
    {
      persistentVolumeClaimName = "storage-horizon"
      accessModes               = ["ReadWriteMany"]
      className                 = "efs-sc-root"
      requestedSize             = "1G"
      enableDataSource          = false
    }
  ]
}

variable "volumes" {
  description = "Additional volumes configuration"
  type = list(object({
    name      = string
    mountPath = string
    persistentVolumeClaim = optional(object({
      claimName = string
    }))
  }))
  default = [
    {
      name      = "storage-horizon-volume"
      mountPath = "/mnt/sqlite"
      persistentVolumeClaim = {
        claimName = "storage-horizon"
      }
    }
  ]
}

# Health checks
variable "liveness_probe" {
  description = "Liveness probe configuration"
  type = object({
    httpGet = object({
      path = string
      port = string
    })
    initialDelaySeconds = number
    periodSeconds       = number
    timeoutSeconds      = number
    failureThreshold    = number
  })
  default = {
    httpGet = {
      path = "/up"
      port = "http"
    }
    initialDelaySeconds = 30
    periodSeconds       = 10
    timeoutSeconds      = 5
    failureThreshold    = 3
  }
}

variable "readiness_probe" {
  description = "Readiness probe configuration"
  type = object({
    httpGet = object({
      path = string
      port = string
    })
    initialDelaySeconds = number
    periodSeconds       = number
    timeoutSeconds      = number
    failureThreshold    = number
  })
  default = {
    httpGet = {
      path = "/up"
      port = "http"
    }
    initialDelaySeconds = 30
    periodSeconds       = 10
    timeoutSeconds      = 5
    failureThreshold    = 3
  }
}

variable "startup_probe" {
  description = "Startup probe configuration"
  type = object({
    httpGet = object({
      path = string
      port = string
    })
    initialDelaySeconds = number
    periodSeconds       = number
    timeoutSeconds      = number
    failureThreshold    = number
  })
  default = {
    httpGet = {
      path = "/up"
      port = "http"
    }
    initialDelaySeconds = 30
    periodSeconds       = 10
    timeoutSeconds      = 5
    failureThreshold    = 3
  }
}

# Node selection
variable "node_selector" {
  description = "Node selector for pod placement"
  type        = map(string)
  default     = {}
}

variable "tolerations" {
  description = "Tolerations for pod placement"
  type = list(object({
    key      = string
    operator = string
    value    = optional(string)
    effect   = optional(string)
  }))
  default = []
}

variable "affinity" {
  description = "Affinity rules for pod placement"
  type        = map(any)
  default     = {}
}

# Service account
variable "service_account" {
  description = "Service account configuration"
  type = object({
    create      = optional(bool, true)
    name        = optional(string, "")
    annotations = optional(map(string), {})
  })
  default = {
    create = true
  }
}

# Labels
variable "labels" {
  description = "Additional labels for resources"
  type        = map(string)
  default     = {}
}

# Product and environment
variable "product" {
  description = "Product name"
  type        = string
  default     = "horizon"
}

variable "env" {
  description = "Environment name"
  type        = string
  default     = "dev"
}
