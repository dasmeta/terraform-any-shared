variable "name" {
  type        = string
  description = "ExternalSecret resource name."

  validation {
    condition     = length(var.name) <= 63 && can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.name))
    error_message = "name must be a lowercase Kubernetes DNS-1123 label of 63 characters or fewer."
  }
}

variable "namespace" {
  type        = string
  description = "Existing namespace containing the ExternalSecret and target Secret."

  validation {
    condition     = length(var.namespace) <= 63 && can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.namespace))
    error_message = "namespace must be a lowercase Kubernetes DNS-1123 label of 63 characters or fewer."
  }
}

variable "secret_store" {
  type = object({
    name = string                          # Existing SecretStore or ClusterSecretStore name.
    kind = optional(string, "SecretStore") # Store resource kind used for retrieval.
  })
  description = "Existing External Secrets Operator store reference."

  validation {
    condition = (
      length(var.secret_store.name) <= 63 &&
      can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.secret_store.name)) &&
      contains(["SecretStore", "ClusterSecretStore"], var.secret_store.kind)
    )
    error_message = "secret_store.name must be a Kubernetes DNS-1123 label and kind must be SecretStore or ClusterSecretStore."
  }
}

variable "remote_key" {
  type        = string
  description = "Provider-side secret identifier that contains every mapped property."

  validation {
    condition     = length(trimspace(var.remote_key)) > 0
    error_message = "remote_key must not be empty."
  }
}

variable "target" {
  type = object({
    name            = string                     # Kubernetes Secret name to create or manage.
    type            = optional(string, "Opaque") # Kubernetes Secret type, for example kubernetes.io/basic-auth.
    creation_policy = optional(string, "Owner")  # ESO target creation and ownership policy.
    deletion_policy = optional(string, "Retain") # ESO behavior when provider data is removed.
  })
  description = "Target Kubernetes Secret and bounded ExternalSecret lifecycle policy."

  validation {
    condition = (
      length(var.target.name) <= 63 &&
      can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.target.name)) &&
      length(trimspace(var.target.type)) > 0 &&
      contains(["Owner", "Orphan", "Merge", "None"], var.target.creation_policy) &&
      contains(["Retain", "Delete", "Merge"], var.target.deletion_policy)
    )
    error_message = "target requires a valid Kubernetes Secret name and type, creation_policy of Owner, Orphan, Merge, or None, and deletion_policy of Retain, Delete, or Merge."
  }
}

variable "mappings" {
  type = list(object({
    secret_key      = string # Key written to the target Kubernetes Secret.
    remote_property = string # Property read from the common provider-side remote key.
  }))
  description = "Explicit provider-property to Kubernetes Secret-key mappings."

  validation {
    condition = (
      length(var.mappings) > 0 &&
      alltrue([for mapping in var.mappings : length(trimspace(mapping.secret_key)) > 0 && length(trimspace(mapping.remote_property)) > 0]) &&
      length(distinct([for mapping in var.mappings : mapping.secret_key])) == length(var.mappings)
    )
    error_message = "mappings must contain one or more non-empty unique secret_key values and non-empty remote_property values."
  }
}

variable "refresh_interval" {
  type        = string
  default     = "1h"
  description = "Periodic ExternalSecret refresh interval as a Go duration string."

  validation {
    condition     = can(regex("^(0s|([0-9]+(\\.[0-9]+)?(ns|us|µs|ms|s|m|h))+)$", var.refresh_interval))
    error_message = "refresh_interval must be 0s or a Go duration string such as 15m, 1h, or 1h30m."
  }
}

variable "labels" {
  type        = map(string)
  default     = {}
  description = "Additional labels applied to the ExternalSecret resource."
}

variable "annotations" {
  type        = map(string)
  default     = {}
  description = "Additional annotations applied to the ExternalSecret resource."
}
