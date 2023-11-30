variable "name" {
  type        = string
  description = "Service names"
}

variable "namespace" {
  type = string
}

variable "helm_values" {
  type = any
}
