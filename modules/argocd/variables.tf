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
  default     = false
  description = "When true, allow Helm to create the target namespace."
}

variable "chart_version" {
  type        = string
  default     = "9.5.2"
  description = "The version of the argoproj/argo-cd Helm chart to deploy."
}

variable "atomic" {
  type        = bool
  default     = true
  description = "Whether to roll back changes made in case of failed release (helm_release.atomic)."
}

variable "cleanup_on_fail" {
  type        = bool
  default     = true
  description = "Allow deletion of new resources created in this upgrade when upgrade fails (helm_release.cleanup_on_fail)."
}

variable "wait" {
  type        = bool
  default     = true
  description = "Whether Helm should wait until all resources are in a ready state before marking the release as successful (helm_release.wait)."
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
    enabled            = optional(bool, true)
    controller         = optional(string, "aws")
    ingress_class_name = optional(string, "alb")
    annotations        = optional(map(string), {})
    path               = optional(string, "/")
    path_type          = optional(string, "Prefix")
    tls_secret_name    = optional(string, null)
  })
  default     = {}
  description = "Ingress configuration for the consumer-managed AWS ALB ingress path."
}

variable "replicas" {
  type        = number
  default     = 2
  description = "The number of Argo CD server replicas."
}

variable "resources" {
  type = object({
    requests = optional(map(string), { cpu = "100m", memory = "256Mi" })
    limits   = optional(map(string), { cpu = "500m", memory = "512Mi" })
  })
  default     = {}
  description = "Resource requests/limits for the Argo CD server workload."
}

variable "autoscaling" {
  type = object({
    enabled                              = optional(bool, false)
    min_replicas                         = optional(number, 1)
    max_replicas                         = optional(number, 5)
    target_cpu_utilization_percentage    = optional(number, 50)
    target_memory_utilization_percentage = optional(number, 50)
    behavior                             = optional(any, {})
    metrics                              = optional(any, [])
  })
  default     = {}
  description = "Argo CD server HPA settings (maps to server.autoscaling in the Helm chart). When enabled, server.replicas is typically ignored by the chart."
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

variable "extra_configs" {
  type        = any
  default     = {}
  description = "Extra Helm values to pass for advanced configuration not covered by this module. Merged on top of module defaults."
}
