variable "name" {
  description = "Stable name for the Kubernetes namespace. Changing it replaces the namespace."
  type        = string

  validation {
    condition     = length(trimspace(var.name)) > 0
    error_message = "Namespace name must not be empty."
  }
}

variable "labels" {
  description = "Caller-managed labels applied to the namespace."
  type        = map(string)
  default     = {}
}

variable "annotations" {
  description = "Caller-managed annotations applied to the namespace."
  type        = map(string)
  default     = {}
}
