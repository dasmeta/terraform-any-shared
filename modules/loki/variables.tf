variable "namespace" {
  type    = string
  default = "loki-stack"
}

variable "name" {
  type        = string
  default     = "loki"
  description = "Chart name"
}

variable "chart_version" {
  type        = string
  default     = "2.10.1"
  description = "Loki-stack grafana chart version"
}

variable "loki_storage" {
  type = object({
    type              = string
    access_key        = string
    secret_access_key = string
    bucketname        = string
    endpoint          = string
    region            = string
    cache_ttl         = optional(string, "168h")
    period            = optional(string, "24h")
  })
  description = "Loki-Stack storage bucket storage configs"
}
