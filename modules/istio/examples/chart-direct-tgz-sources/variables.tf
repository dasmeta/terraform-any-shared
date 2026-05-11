variable "enable_istio_gateway_chart" {
  type        = bool
  description = "Whether to install the optional Istio gateway Helm chart in addition to Gateway API managed gateways"
  default     = false
}

variable "enable_kiali" {
  type        = bool
  description = "Whether to install Kiali from a direct chart archive URL as part of the local test"
  default     = true
}
