variable "name" {
  type        = string
  description = "CloudNativePG Cluster name. It also determines the read/write Service and optional ScheduledBackup name."

  validation {
    condition     = length(var.name) <= 57 && can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.name))
    error_message = "name must be a lowercase DNS-1123 label of 57 characters or fewer."
  }
}

variable "namespace" {
  type        = string
  description = "Existing Kubernetes namespace where the CNPG Cluster and credential Secrets reside."

  validation {
    condition     = length(var.namespace) <= 63 && can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.namespace))
    error_message = "namespace must be a lowercase Kubernetes DNS-1123 label of 63 characters or fewer."
  }
}

variable "instances" {
  type        = number
  description = "Desired number of CloudNativePG instances. Set explicitly to match the workload availability target."

  validation {
    condition     = var.instances >= 1 && floor(var.instances) == var.instances
    error_message = "instances must be a positive integer."
  }
}

variable "storage" {
  type = object({
    class = string
    size  = string
  })
  description = "StorageClass and requested persistent-volume capacity for each CNPG instance."

  validation {
    condition = (
      length(trimspace(var.storage.class)) > 0 &&
      can(regex("^[1-9][0-9]*([EPTGMK]i?|m)?$", var.storage.size))
    )
    error_message = "storage.class must not be empty and storage.size must be a positive Kubernetes quantity such as 10Gi."
  }
}

variable "database" {
  type = object({
    name                  = string
    owner                 = string
    bootstrap_secret_name = string
  })
  description = "Initial application database and owner. bootstrap_secret_name is an existing same-namespace kubernetes.io/basic-auth Secret with username and password keys; its values are never read by Terraform."

  validation {
    condition = (
      can(regex("^[a-z_][a-z0-9_]*$", var.database.name)) &&
      can(regex("^[a-z_][a-z0-9_]*$", var.database.owner)) &&
      can(regex("^[a-z0-9]([-a-z0-9.]*[a-z0-9])?$", var.database.bootstrap_secret_name))
    )
    error_message = "database.name and database.owner must be lowercase PostgreSQL identifiers, and database.bootstrap_secret_name must be a lowercase Kubernetes Secret name."
  }
}

variable "image_name" {
  type        = string
  default     = "ghcr.io/cloudnative-pg/postgresql:16.13@sha256:425e365273a0519c9cc1deb199a69c226734041a9a59a1f8250fecb06f6dcbb5"
  description = "Pinned CloudNativePG PostgreSQL image. Override only after reviewing the operator and PostgreSQL upgrade path."

  validation {
    condition     = length(trimspace(var.image_name)) > 0
    error_message = "image_name must not be empty."
  }
}

variable "labels" {
  type        = map(string)
  default     = {}
  description = "Additional labels applied to the Cluster resource."
}

variable "annotations" {
  type        = map(string)
  default     = {}
  description = "Additional annotations applied to the Cluster resource."
}

variable "resources" {
  type = object({
    limits   = optional(map(string), {})
    requests = optional(map(string), {})
  })
  default     = {}
  description = "Optional CPU and memory requests and limits for each PostgreSQL instance."
}

variable "postgresql_parameters" {
  type        = map(string)
  default     = {}
  description = "Additional PostgreSQL parameters merged with the enforced SCRAM password encryption setting."
}

variable "enable_pod_monitor" {
  type        = bool
  default     = true
  description = "Whether CNPG should create a PodMonitor. Set false when the Prometheus Operator CRDs are unavailable."
}

variable "pod_anti_affinity_type" {
  type        = string
  default     = "required"
  description = "CNPG hostname pod anti-affinity policy. required provides high availability where nodes allow it; preferred relaxes scheduling pressure."

  validation {
    condition     = contains(["required", "preferred"], var.pod_anti_affinity_type)
    error_message = "pod_anti_affinity_type must be either required or preferred."
  }
}

variable "backup" {
  type = object({
    destination_path        = string
    credentials_secret_name = string
    access_key_id_key       = optional(string, "access-key-id")
    secret_access_key_key   = optional(string, "secret-access-key")
    endpoint_url            = optional(string)
    region_key              = optional(string)
    session_token_key       = optional(string)
    retention_policy        = optional(string, "30d")
    schedule                = optional(string, "0 0 0 * * *")
    immediate               = optional(bool, true)
  })
  default     = null
  description = "Optional S3-compatible Barman recovery configuration. credentials_secret_name is an existing same-namespace Secret; Terraform only renders key references. schedule uses CNPG's six-field cron format including seconds."

  validation {
    condition = var.backup == null || (
      can(regex("^s3://[^/]+/.+", var.backup.destination_path)) &&
      can(regex("^[a-z0-9]([-a-z0-9.]*[a-z0-9])?$", var.backup.credentials_secret_name)) &&
      length(trimspace(var.backup.access_key_id_key)) > 0 &&
      length(trimspace(var.backup.secret_access_key_key)) > 0 &&
      (var.backup.endpoint_url == null || can(regex("^https?://", var.backup.endpoint_url))) &&
      (var.backup.region_key == null || length(trimspace(var.backup.region_key)) > 0) &&
      (var.backup.session_token_key == null || length(trimspace(var.backup.session_token_key)) > 0) &&
      can(regex("^[1-9][0-9]*[dwm]$", var.backup.retention_policy)) &&
      length(split(" ", var.backup.schedule)) == 6
    )
    error_message = "backup requires an s3:// destination path, valid existing Secret reference and keys, optional HTTP(S) endpoint, positive d/w/m retention, and a six-field CNPG schedule."
  }
}
