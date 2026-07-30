variable "name" {
  description = "Stable Kubernetes DNS-1123 namespace label. Changing it replaces the namespace."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.name)) && length(var.name) <= 63
    error_message = "Namespace name must be a lowercase Kubernetes DNS-1123 label of 1 to 63 characters."
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
