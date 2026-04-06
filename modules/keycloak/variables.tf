variable "name" {
  type        = string
  default     = "keycloak"
  description = "The name of the Helm release."
}

variable "namespace" {
  type        = string
  default     = "keycloak"
  description = "The Kubernetes namespace where Keycloak is deployed."
}

variable "create_namespace" {
  type        = bool
  default     = true
  description = "When true, create the target namespace with the Kubernetes provider before secrets and Helm (required so bootstrap Secrets can be applied)."
}

variable "chart_version" {
  type        = string
  default     = "7.1.9"
  description = "The version of the codecentric/keycloakx Helm chart to deploy."
}

variable "helm_timeout" {
  type        = number
  default     = 900
  description = "Seconds Helm waits for the release when wait is true. Keycloak startup often exceeds the provider default (300s), causing context deadline exceeded with atomic installs."
}

variable "hostname" {
  type        = string
  description = "The public hostname configured for Keycloak."
}

variable "hostname_strict" {
  type        = bool
  default     = false
  description = "When false, sets KC_HOSTNAME_STRICT=false so Keycloak accepts any Host header (e.g. kubectl port-forward to 127.0.0.1 without redirects to hostname). Set true when public URLs must strictly match hostname."
}

variable "proxy_mode" {
  type        = string
  default     = "xforwarded"
  description = "Sets keycloakx chart proxy.mode"
}

variable "replicas" {
  type        = number
  default     = 1
  description = "The number of Keycloak replicas to run."
}

variable "admin_username" {
  type        = string
  default     = "admin"
  description = "The initial Keycloak admin username."
}

variable "admin_password" {
  type        = string
  default     = null
  description = "Raw admin password used only when the module manages the bootstrap secret."
  sensitive   = true
}

variable "admin_password_secret_name" {
  type        = string
  default     = null
  description = "Existing Kubernetes Secret name that contains the Keycloak admin password."
}

variable "admin_password_secret_key" {
  type        = string
  default     = "password"
  description = "The key inside the admin password Secret."
}

variable "database" {
  type = object({
    host                 = string
    name                 = string
    username             = string
    vendor               = optional(string, "postgres")
    port                 = optional(number, 5432)
    password             = optional(string)
    password_secret_name = optional(string)
    password_secret_key  = optional(string, "password")
  })
  description = "The external database configuration for Keycloak."
  sensitive   = true
}

variable "ingress" {
  type = object({
    enabled            = optional(bool, true)
    ingress_class_name = optional(string)
    annotations        = optional(map(string), {})
    path               = optional(string, "/")
    path_type          = optional(string, "Prefix")
    tls_secret_name    = optional(string)
  })
  default     = {}
  description = "Ingress configuration for the consumer-managed ingress path."
}

variable "resources" {
  type = object({
    limits   = optional(map(string), {})
    requests = optional(map(string), {})
  })
  default     = {}
  description = "CPU and memory resource requests and limits for Keycloak."
}

variable "pod_labels" {
  type        = map(string)
  default     = {}
  description = "Additional labels applied to the Keycloak pod."
}
