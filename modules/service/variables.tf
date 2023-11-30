variable "name" {
  type        = string
  description = "Service names"
}

variable "namespace" {
  type        = string
  description = "Namespace"
}

variable "helm_values" {
  type        = any
  description = "Values which is overwrite chart defaults"
}
