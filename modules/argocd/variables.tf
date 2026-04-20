variable "name" {
  type        = string
  default     = "argocd"
  description = "The name of the Helm release."
}

variable "namespace" {
  type        = string
  default     = "argocd"
  description = "The Kubernetes namespace where Argo CD is deployed."
}

variable "create_namespace" {
  type        = bool
  default     = true
  description = "When true, create the target namespace with the Kubernetes provider before Helm."
}

variable "chart_version" {
  type        = string
  default     = "9.5.0"
  description = "The version of the argoproj/argo-cd Helm chart to deploy."
}

variable "helm_timeout" {
  type        = number
  default     = 900
  description = "Seconds Helm waits for the release when wait is true."
}

variable "hostname" {
  type        = string
  default     = null
  description = "The Argo CD server hostname used when ingress is enabled."
}

variable "ingress" {
  type = object({
    enabled         = optional(bool, true)
    annotations     = optional(map(string), {})
    path            = optional(string, "/")
    path_type       = optional(string, "Prefix")
    tls_secret_name = optional(string, null)
  })
  default     = {}
  description = "Ingress configuration for the consumer-managed AWS ALB ingress path."
}

variable "admin_password_bcrypt" {
  type        = string
  default     = null
  description = "Bcrypt hash for the Argo CD admin password (not plaintext). Stored in Terraform state as a sensitive value when set."
  sensitive   = true
}

variable "use_existing_admin_secret" {
  type        = bool
  default     = false
  description = "When true, do not manage admin password material and expect an existing argocd-secret in the target namespace."
}
