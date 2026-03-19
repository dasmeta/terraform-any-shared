variable "name" {
  description = "The name of the Helm release."
  type        = string
  default     = "defectdojo"
}

variable "chart_version" {
  description = "The DefectDojo Helm chart version to use."
  type        = string
  default     = "1.9.14"
}

variable "namespace" {
  description = "The Kubernetes namespace to install DefectDojo."
  type        = string
  default     = "defectdojo"
}

variable "create_namespace" {
  description = "Create the namespace if it does not exist."
  type        = bool
  default     = true
}

variable "wait" {
  description = "Wait for the release to be deployed successfully."
  type        = bool
  default     = true
}

variable "atomic" {
  description = "If set, the installation process will be rolled back on failure."
  type        = bool
  default     = false
}

variable "default_configs" {
  description = "Default values to pass to the Helm chart. Override specific fields via custom_configs."
  type        = any
  default = {
    createSecret           = true
    createValkeySecret     = true
    createPostgresqlSecret = true
  }
}

variable "custom_configs" {
  description = "Additional or override values for the Helm chart. Merged on top of default_configs. See https://artifacthub.io/packages/helm/defectdojo/defectdojo?modal=values"
  type        = any
  default     = {}
}
