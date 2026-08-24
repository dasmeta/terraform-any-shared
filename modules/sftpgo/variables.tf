variable "name" {
  type        = string
  default     = "sftpgo"
  description = "The Helm release name."

  validation {
    condition     = length(trimspace(var.name)) > 0
    error_message = "name must not be empty."
  }
}

variable "namespace" {
  type        = string
  default     = "sftpgo"
  description = "The Kubernetes namespace where SFTPGo is deployed."

  validation {
    condition     = length(trimspace(var.namespace)) > 0
    error_message = "namespace must not be empty."
  }
}

variable "create_namespace" {
  type        = bool
  default     = true
  description = "Whether Helm should create the namespace."
}

variable "chart_repository" {
  type        = string
  default     = "oci://ghcr.io/sftpgo/helm-charts"
  description = "The SFTPGo Helm chart repository."
}

variable "chart" {
  type        = string
  default     = "sftpgo"
  description = "The SFTPGo Helm chart name."
}

variable "chart_version" {
  type        = string
  default     = "0.45.0"
  description = "The SFTPGo Helm chart version."
}

variable "atomic" {
  type        = bool
  default     = true
  description = "Whether Helm should roll back changes made in case of failed release."
}

variable "wait" {
  type        = bool
  default     = true
  description = "Whether Helm should wait until all resources are ready."
}

variable "cleanup_on_fail" {
  type        = bool
  default     = true
  description = "Whether Helm should delete new resources created during a failed install or upgrade."
}

variable "timeout" {
  type        = number
  default     = 600
  description = "Seconds Helm waits for the release when wait is true."
}

variable "replica_count" {
  type        = number
  default     = 1
  description = "The number of SFTPGo replicas."
}

variable "admin" {
  type = object({
    enabled  = optional(bool, true)
    username = optional(string, "admin")
    password = string
  })
  description = "Default SFTPGo admin bootstrap configuration. The password is supplied through Terraform and stored in state as sensitive."
  sensitive   = true

  validation {
    condition     = length(trimspace(var.admin.password)) > 0
    error_message = "admin.password must not be empty."
  }
}

variable "web_session" {
  type = object({
    signing_passphrase = string
    cookie_lifetime    = optional(number, 720)
    token_validation   = optional(number, 0)
  })
  default     = null
  description = "Optional SFTPGo WebAdmin/WebClient session settings. signing_passphrase must remain stable across pod restarts and is supplied through Terraform as a sensitive value."
  sensitive   = true

  validation {
    condition = var.web_session == null ? true : (
      length(trimspace(var.web_session.signing_passphrase)) > 0 &&
      var.web_session.cookie_lifetime >= 1 &&
      var.web_session.cookie_lifetime <= 720 &&
      var.web_session.token_validation >= 0 &&
      var.web_session.token_validation <= 3
    )
    error_message = "web_session.signing_passphrase must be non-empty, cookie_lifetime must be between 1 and 720 minutes, and token_validation must be between 0 and 3."
  }
}

variable "s3_storage" {
  type = object({
    bucket           = string
    region           = string
    access_key       = string
    access_secret    = string
    endpoint         = optional(string)
    force_path_style = optional(bool)
  })
  description = "S3 storage configuration used by bootstrap users. access_secret is supplied through Terraform and stored in state as sensitive."
  sensitive   = true

  validation {
    condition = alltrue([
      length(trimspace(var.s3_storage.bucket)) > 0,
      length(trimspace(var.s3_storage.region)) > 0,
      length(trimspace(var.s3_storage.access_key)) > 0,
      length(trimspace(var.s3_storage.access_secret)) > 0,
    ])
    error_message = "s3_storage.bucket, region, access_key, and access_secret must not be empty."
  }
}

variable "bootstrap_users" {
  type = list(object({
    username                = string
    password                = string
    key_prefix              = optional(string)
    home_dir                = optional(string)
    require_password_change = optional(bool, true)
  }))
  description = "SFTPGo users to create or update during bootstrap. Passwords are supplied through Terraform and stored in state as sensitive."
  sensitive   = true

  validation {
    condition     = length(var.bootstrap_users) > 0
    error_message = "bootstrap_users must include at least one user."
  }

  validation {
    condition = alltrue([
      for user in var.bootstrap_users :
      length(trimspace(user.username)) > 0 && length(trimspace(user.password)) > 0
    ])
    error_message = "Each bootstrap user must include a non-empty username and password."
  }
}

variable "persistence" {
  type = object({
    enabled            = optional(bool, true)
    storage_class_name = optional(string)
    access_modes       = optional(list(string), ["ReadWriteOnce"])
    storage            = optional(string, "10Gi")
  })
  default     = {}
  description = "SFTPGo persistence configuration."
}

variable "sftp_service" {
  type = object({
    enabled                     = optional(bool, false)
    type                        = optional(string, "LoadBalancer")
    port                        = optional(number, 22)
    annotations                 = optional(map(string), {})
    load_balancer_class         = optional(string, "service.k8s.aws/nlb")
    load_balancer_source_ranges = optional(list(string), [])
  })
  default     = {}
  description = "Optional Kubernetes Service for SFTP-only TCP exposure. When enabled, the service selects the SFTPGo pods and exposes only the SFTP port."

  validation {
    condition     = contains(["ClusterIP", "NodePort", "LoadBalancer"], var.sftp_service.type)
    error_message = "sftp_service.type must be one of ClusterIP, NodePort, or LoadBalancer."
  }

  validation {
    condition     = var.sftp_service.port >= 1 && var.sftp_service.port <= 65535
    error_message = "sftp_service.port must be between 1 and 65535."
  }
}

variable "resources" {
  type = object({
    requests = optional(map(string), {
      cpu    = "250m"
      memory = "512Mi"
    })
    limits = optional(map(string), {
      cpu    = "500m"
      memory = "1Gi"
    })
  })
  default     = {}
  description = "SFTPGo container resource requests and limits."
}

variable "strategy" {
  type = object({
    type = optional(string, "Recreate")
  })
  default     = {}
  description = "SFTPGo deployment strategy values passed to the chart."
}

variable "image_pull_secrets" {
  type        = list(object({ name = string }))
  default     = []
  description = "Image pull secrets passed to the SFTPGo chart."
}

variable "bootstrap_image" {
  type        = string
  default     = "python:3.12-alpine"
  description = "Container image used for the SFTPGo user bootstrap sidecar."
}

variable "extra_values" {
  type        = any
  default     = {}
  description = "Additional SFTPGo Helm values merged last. Use sparingly for chart options outside this module's opinionated interface."
}
