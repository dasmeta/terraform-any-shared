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

variable "chart" {
  type        = string
  default     = "base"
  description = "The name of the Helm chart to deploy."
}

variable "repository" {
  type        = string
  default     = "https://dasmeta.github.io/helm/"
  description = "The URL of the Helm chart repository."
}
