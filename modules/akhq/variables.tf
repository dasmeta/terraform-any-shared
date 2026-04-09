variable "name" {
  type        = string
  default     = "akhq"
  description = "Name of the Helm release."
}

variable "namespace" {
  type        = string
  default     = "akhq"
  description = "Kubernetes namespace for AKHQ."
}

variable "create_namespace" {
  type        = bool
  default     = true
  description = "Create the namespace with the Kubernetes provider before the Helm release."
}

variable "chart_version" {
  type        = string
  default     = "0.27.0"
  description = "Version of the tchiotludo/akhq Helm chart (repo https://akhq.io/)."
}

variable "helm_timeout" {
  type        = number
  default     = 600
  description = "Helm wait timeout in seconds."
}

variable "replicas" {
  type        = number
  default     = 1
  description = "Deployment replica count (chart value replicaCount)."
}

variable "hostname" {
  type        = string
  description = "Hostname for Ingress when ingress.enabled is true."
}

variable "network_policy_enabled" {
  type        = bool
  default     = false
  description = "Set chart networkPolicy.enabled. Disable if your cluster/network policies block AKHQ by default."
}

variable "kafka" {
  type = object({
    connection_name   = optional(string, "kafka")
    bootstrap_servers = string
    properties        = optional(map(string), {})
  })
  description = "Kafka cluster connection (non-sensitive properties only; use kafka_secret_properties for SASL/SSL secrets)."
}

variable "kafka_secret_properties" {
  type        = map(string)
  default     = {}
  description = "Sensitive Kafka client properties merged into Helm secrets for the connection (e.g. sasl.jaas.config). Keys here override the same keys from kafka_scram_username/kafka_scram_password."
  sensitive   = true
}

variable "kafka_scram_username" {
  type        = string
  default     = null
  description = "Optional MSK SCRAM-SHA-512 username; combined with kafka_scram_password to set sasl.jaas.config. Omit if you pass the full line in kafka_secret_properties instead."
}

variable "kafka_scram_password" {
  type        = string
  default     = null
  sensitive   = true
  description = "Optional MSK SCRAM-SHA-512 password; used with kafka_scram_username."
}

variable "security" {
  type = object({
    enabled                       = optional(bool, true)
    basic_auth_username           = optional(string, "admin")
    basic_auth_password           = optional(string)
    basic_auth_password_prehashed = optional(bool, false)
    basic_auth_groups             = optional(list(string), ["admin"])
    micronaut_jwt_secret          = optional(string)
  })
  default = {
    enabled = true
  }
  description = "AKHQ UI authentication. When enabled, basic_auth_password is required unless you use existing_secrets for all secret material. basic_auth_password must be plaintext unless basic_auth_password_prehashed is true (then supply SHA-256 hex as AKHQ expects)."
}

variable "existing_secrets" {
  type        = string
  default     = null
  description = "If set, chart uses this Secret name for application-secrets.yml instead of chart-created secrets (you manage content)."
}

variable "ingress" {
  type = object({
    enabled            = optional(bool, true)
    ingress_class_name = optional(string)
    annotations        = optional(map(string), {})
    path               = optional(string, "/")
    path_type          = optional(string, "Prefix")
    tls = optional(list(object({
      secretName = string
      hosts      = list(string)
    })), [])
  })
  default     = {}
  description = "Ingress configuration for networking.k8s.io/Ingress (e.g. ALB, nginx)."
}

variable "resources" {
  type = object({
    limits   = optional(map(string), {})
    requests = optional(map(string), {})
  })
  default     = {}
  description = "Container resources for the AKHQ pod."
}

variable "pod_labels" {
  type        = map(string)
  default     = {}
  description = "Extra pod labels passed to the chart."
}

variable "extra_configuration" {
  type        = any
  default     = {}
  description = "Merged into chart configuration (ConfigMap). Use for advanced AKHQ/micronaut settings; shallow merge at root keys."
}
