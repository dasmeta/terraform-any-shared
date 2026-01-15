variable "name" {
  description = "Name of the Helm release for Qdrant."
  type        = string
  default     = "qdrant"
}

variable "namespace" {
  description = "Kubernetes namespace where the Qdrant Helm release will be deployed."
  type        = string
}

variable "create_namespace" {
  description = "Whether to create the Kubernetes namespace if it does not already exist."
  type        = bool
  default     = false
}

variable "chart_repo" {
  description = "Helm repository URL that hosts the Qdrant chart."
  type        = string
  default     = "https://qdrant.github.io/qdrant-helm"
}

variable "chart_name" {
  description = "Name of the Helm chart to deploy from the repository."
  type        = string
  default     = "qdrant"
}

variable "chart_version" {
  description = "Specific version of the Qdrant Helm chart to deploy. If empty, the latest available version is used."
  type        = string
  default     = "1.16.3"
}

variable "config" {
  description = <<EOF
Map of Helm values that override the module's default chart configuration.
The values provided here are shallow-merged on top of the defaults and are
passed directly to the Qdrant Helm chart.
EOF
  type        = any
  default     = {}
}
