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
    signing_passphrase = optional(string)
    signing_passphrase_secret_ref = optional(object({
      name = string
      key  = string
    }))
    cookie_lifetime  = optional(number, 720)
    token_validation = optional(number, 0)
  })
  default     = null
  description = "Optional WebAdmin/WebClient session settings. Supply exactly one stable signing_passphrase or signing_passphrase_secret_ref referencing an existing Secret in the release namespace. Literal values are stored in Terraform state; references do not read the secret."
  sensitive   = true

  validation {
    condition = var.web_session == null ? true : (
      (var.web_session.signing_passphrase != null) != (var.web_session.signing_passphrase_secret_ref != null) &&
      (var.web_session.signing_passphrase == null ? true : length(trimspace(var.web_session.signing_passphrase)) > 0) &&
      (var.web_session.signing_passphrase_secret_ref == null ? true : try(
        length(trimspace(var.web_session.signing_passphrase_secret_ref.name)) > 0 &&
        length(trimspace(var.web_session.signing_passphrase_secret_ref.key)) > 0, false
      )) &&
      var.web_session.cookie_lifetime >= 1 &&
      var.web_session.cookie_lifetime <= 720 &&
      var.web_session.token_validation >= 0 &&
      var.web_session.token_validation <= 3
    )
    error_message = "web_session requires exactly one non-empty signing_passphrase or signing_passphrase_secret_ref with non-empty name/key; cookie_lifetime must be between 1 and 720 minutes and token_validation between 0 and 3."
  }
}

variable "web_proxy" {
  type = object({
    proxy_allowed          = list(string)
    client_ip_proxy_header = optional(string, "X-Forwarded-For")
    client_ip_header_depth = optional(number, 0)
  })
  default     = null
  description = "Optional trusted HTTP proxy configuration for the WebAdmin, WebClient and REST API binding on port 8080. Trust only proxy CIDRs and restrict direct HTTP access to the proxy path. Header depth counts from the right."

  validation {
    condition = var.web_proxy == null ? true : try(
      length(var.web_proxy.proxy_allowed) > 0 && alltrue([
        for cidr in var.web_proxy.proxy_allowed :
        can(cidrhost(cidr, 0)) && tonumber(split("/", cidr)[1]) > 0
      ]),
      false
    )
    error_message = "web_proxy.proxy_allowed must contain valid IPv4 or IPv6 CIDRs; empty lists, null entries and universal /0 ranges are not allowed."
  }

  validation {
    condition = var.web_proxy == null ? true : (
      length(trimspace(var.web_proxy.client_ip_proxy_header)) > 0 &&
      var.web_proxy.client_ip_header_depth >= 0 &&
      floor(var.web_proxy.client_ip_header_depth) == var.web_proxy.client_ip_header_depth
    )
    error_message = "web_proxy.client_ip_proxy_header must be non-empty and client_ip_header_depth must be a nonnegative integer (0 trusts the rightmost address)."
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
  default     = []
  nullable    = false
  description = "SFTPGo users to create or update during bootstrap. An empty list disables the bootstrap sidecar without deleting existing users. Passwords are stored in Terraform state as sensitive."
  sensitive   = true

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
    external_traffic_policy     = optional(string, "Cluster")
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
    condition     = contains(["Cluster", "Local"], var.sftp_service.external_traffic_policy)
    error_message = "sftp_service.external_traffic_policy must be Cluster or Local."
  }

  validation {
    condition     = var.sftp_service.type != "ClusterIP" || var.sftp_service.external_traffic_policy == "Cluster"
    error_message = "sftp_service.external_traffic_policy = Local requires a LoadBalancer or NodePort Service."
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

variable "shutdown" {
  type = object({
    grace_time                       = optional(number, 300)
    termination_grace_period_seconds = optional(number, 330)
  })
  default     = null
  description = "Optional planned shutdown settings. SFTPGo waits up to grace_time seconds for transfers; the pod termination period must be longer. Coordinate load balancer draining and Helm timeout separately."

  validation {
    condition = var.shutdown == null ? true : (
      var.shutdown.grace_time > 0 &&
      floor(var.shutdown.grace_time) == var.shutdown.grace_time &&
      var.shutdown.termination_grace_period_seconds > var.shutdown.grace_time &&
      floor(var.shutdown.termination_grace_period_seconds) == var.shutdown.termination_grace_period_seconds
    )
    error_message = "shutdown requires a positive integer grace_time and a strictly larger integer termination_grace_period_seconds."
  }
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
