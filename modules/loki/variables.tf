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
    access_key        = optional(string, "")
    secret_access_key = optional(string, "")
    bucketname        = optional(string, "")
    endpoint          = optional(string, "")
    region            = optional(string, "")
    cache_ttl         = optional(string, "168h")
    period            = optional(string, "24h")
  })
  description = "Loki-Stack storage bucket configs"
}
