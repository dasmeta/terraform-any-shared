variable "name" {
  type        = string
  description = "CloudNativePG Cluster name. It determines the generated read/write and read-only Service names."

  validation {
    condition     = length(var.name) <= 57 && can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.name))
    error_message = "name must be a lowercase DNS-1123 label of 57 characters or fewer to keep generated CNPG Service names valid."
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
    class = string # StorageClass used for each PostgreSQL instance volume.
    size  = string # Positive whole-byte Kubernetes storage quantity, such as 10Gi.
  })
  description = "StorageClass and requested persistent-volume capacity for each CNPG instance."

  validation {
    condition = (
      length(trimspace(var.storage.class)) > 0 &&
      can(regex("^[1-9][0-9]*(\\.[0-9]+)?([EPTGM]i?|Ki|[EPTGM]|k)?$", var.storage.size))
    )
    error_message = "storage.class must not be empty and storage.size must be a positive whole-byte Kubernetes quantity such as 10Gi or 1.5Gi; milli-byte suffixes are not allowed."
  }
}

variable "database" {
  type = object({
    name                  = string # Initial PostgreSQL database name.
    owner                 = string # Initial PostgreSQL owner role name.
    bootstrap_secret_name = string # Existing same-namespace basic-auth Secret name.
  })
  description = "Initial application database and owner. bootstrap_secret_name is an existing same-namespace kubernetes.io/basic-auth Secret with username and password keys; its values are never read by Terraform."

  validation {
    condition = (
      length(var.database.name) <= 63 &&
      length(var.database.owner) <= 63 &&
      can(regex("^[a-z_][a-z0-9_]*$", var.database.name)) &&
      can(regex("^[a-z_][a-z0-9_]*$", var.database.owner)) &&
      can(regex("^[a-z0-9]([-a-z0-9.]*[a-z0-9])?$", var.database.bootstrap_secret_name))
    )
    error_message = "database.name and database.owner must be lowercase PostgreSQL identifiers of at most 63 characters, and database.bootstrap_secret_name must be a lowercase Kubernetes Secret name."
  }
}

variable "image_name" {
  type        = string
  default     = "ghcr.io/cloudnative-pg/postgresql:16.13-system-bookworm@sha256:98df8a04201d957af5975be2a2d52f357b8cfdc11f554a76be0321b0660ebfb6"
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
    limits   = optional(map(string), {}) # Optional resource limits for each PostgreSQL instance.
    requests = optional(map(string), {}) # Optional resource requests for each PostgreSQL instance.
  })
  default     = {}
  description = "Optional CPU and memory requests and limits for each PostgreSQL instance."
}

variable "postgresql_parameters" {
  type        = map(string)
  default     = {}
  description = "Additional PostgreSQL parameters merged with the enforced SCRAM password encryption setting."
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
