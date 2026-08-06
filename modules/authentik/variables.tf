variable "name" {
  type        = string
  default     = "authentik"
  description = "Helm release name and stable Authentik resource prefix."

  validation {
    condition     = length(var.name) <= 56 && can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.name))
    error_message = "name must be a lowercase DNS label of 56 characters or fewer so the derived server Service name remains valid."
  }
}

variable "namespace" {
  type        = string
  description = "Existing Kubernetes namespace where Authentik is deployed."

  validation {
    condition     = length(trimspace(var.namespace)) > 0
    error_message = "namespace must not be empty."
  }
}

variable "chart_version" {
  type        = string
  default     = "2026.5.6"
  description = "Reviewed version of the official Authentik Helm chart."

  validation {
    condition     = length(trimspace(var.chart_version)) > 0
    error_message = "chart_version must not be empty."
  }
}

variable "configuration_secret_name" {
  type        = string
  description = "Existing Secret name containing AUTHENTIK_SECRET_KEY and AUTHENTIK_POSTGRESQL__PASSWORD."

  validation {
    condition     = can(regex("^[a-z0-9]([-a-z0-9.]*[a-z0-9])?$", var.configuration_secret_name))
    error_message = "configuration_secret_name must be a valid lowercase Kubernetes Secret name."
  }
}

variable "database" {
  type = object({
    host = string                 # External PostgreSQL hostname or service name.
    name = string                 # Existing PostgreSQL database name.
    user = string                 # Existing PostgreSQL username.
    port = optional(number, 5432) # External PostgreSQL TCP port (integer from 1 through 65535).
  })
  description = "Non-secret connection metadata for the externally provisioned Authentik PostgreSQL database."

  validation {
    condition = (
      length(trimspace(var.database.host)) > 0 &&
      length(trimspace(var.database.name)) > 0 &&
      length(trimspace(var.database.user)) > 0 &&
      var.database.port >= 1 &&
      var.database.port <= 65535 &&
      floor(var.database.port) == var.database.port
    )
    error_message = "database host, name, and user must not be empty, and port must be an integer between 1 and 65535."
  }
}

variable "ingress" {
  type = object({
    enabled         = optional(bool, false)     # Creates the NGINX Ingress when true.
    hostname        = optional(string, "")      # Public DNS hostname routed to Authentik.
    tls_secret_name = optional(string, "")      # Same-namespace TLS Secret populated by cert-manager.
    cluster_issuer  = optional(string, "")      # cert-manager ClusterIssuer that requests the certificate.
    annotations     = optional(map(string), {}) # Additional non-reserved NGINX Ingress annotations.
  })
  default     = null
  description = "Optional NGINX HTTPS ingress configuration. When enabled, hostname, tls_secret_name and cluster_issuer are required. DNS remains externally managed. Omit or set null to preserve any ingress values supplied through extra_helm_config."

  validation {
    condition = var.ingress == null || !var.ingress.enabled || (
      length(trimspace(var.ingress.hostname)) > 0 &&
      length(var.ingress.tls_secret_name) <= 253 &&
      length(var.ingress.cluster_issuer) <= 253 &&
      can(regex("^([a-z0-9]([-a-z0-9]*[a-z0-9])?)(\\.([a-z0-9]([-a-z0-9]*[a-z0-9])?))*$", var.ingress.tls_secret_name)) &&
      can(regex("^([a-z0-9]([-a-z0-9]*[a-z0-9])?)(\\.([a-z0-9]([-a-z0-9]*[a-z0-9])?))*$", var.ingress.cluster_issuer))
    )
    error_message = "Enabled ingress requires a hostname, valid TLS Secret name and valid ClusterIssuer name."
  }
}

variable "extra_helm_config" {
  type        = any
  default     = {}
  description = "Additional official Authentik chart values. Required module-owned database, Secret, release identity, and ClusterIP service values take precedence."
}
