variable "chart_version" {
  type        = string
  default     = "0.1.0"
  description = "The app chart version to use"
}

variable "namespace" {
  description = "The namespace to install app helm."
  type        = string
  default     = "meta-system"
}

variable "create_namespace" {
  type        = bool
  default     = false
  description = "Create namespace if requested"
}

variable "webhookendpoint" {
  type        = any
  default     = ""
  description = "Webhook endpoint to send events to. If not set, the exporter will not send events."
}
