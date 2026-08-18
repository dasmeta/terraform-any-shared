variable "runner_name" {
  type        = string
  description = "Runner Name"
  default     = "runner"
}

variable "personal_access_token" {
  type        = string
  description = "GitHub personal access token used by the controller. Set to null when github_auth_secret_name is provided."
  default     = null
  sensitive   = true
  nullable    = true

  validation {
    condition     = var.personal_access_token == null || try(trimspace(var.personal_access_token) != "", false)
    error_message = "personal_access_token must be null or a non-empty string."
  }
}

variable "repo_name" {
  type        = string
  default     = null
  description = "GitHub repository in owner/name form for the legacy single-repository mode. Required when runner_scope is empty."
  nullable    = true

  validation {
    condition = (
      var.repo_name == null ||
      can(regex("^[^/[:space:]]+/[^/[:space:]]+$", var.repo_name))
    )
    error_message = "repo_name must be null or use non-empty owner/name form without whitespace."
  }
}

variable "kubectl_config_path" {
  type        = string
  default     = "~/.kube/config"
  description = "Kubernetes config path. Set to null to let the kubectl provider use KUBE_* environment credentials, as in Terraform Cloud."
  nullable    = true

  validation {
    condition     = var.kubectl_config_path == null || try(trimspace(var.kubectl_config_path) != "", false)
    error_message = "kubectl_config_path must be null or a non-empty path."
  }
}

variable "github_auth_secret_name" {
  type        = string
  description = "Name of an existing Secret in namespace containing the controller github_token key. Mutually exclusive with personal_access_token."
  default     = null
  nullable    = true

  validation {
    condition = var.github_auth_secret_name == null || (
      length(var.github_auth_secret_name) <= 63 &&
      can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.github_auth_secret_name))
    )
    error_message = "github_auth_secret_name must be null or a valid Kubernetes DNS label of at most 63 characters."
  }
}

variable "namespace" {
  type        = string
  description = "Kubernetes namespace in which the legacy runner controller and Runner resources are installed."
  default     = "actions-runner-system"

  validation {
    condition = (
      length(var.namespace) <= 63 &&
      can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.namespace))
    )
    error_message = "namespace must be a valid Kubernetes DNS label of at most 63 characters."
  }
}

variable "chart_version" {
  type        = string
  description = "Optional legacy actions-runner-controller Helm chart version. Null preserves the historical latest-compatible selection."
  default     = null
  nullable    = true

  validation {
    condition     = var.chart_version == null || try(trimspace(var.chart_version) != "", false)
    error_message = "chart_version must be null or a non-empty version string."
  }
}

variable "runner_scope" {
  type = object({
    repositories = optional(set(string), []) # Explicit GitHub repositories in owner/name form.
    organization = optional(string)          # GitHub organization name for organization-wide runners.
  })
  description = "Optional runner target selection. Set repositories or organization, but not both. An empty object preserves repo_name behavior."
  default     = {}

  validation {
    condition = !(
      length(var.runner_scope.repositories) > 0 &&
      try(trimspace(var.runner_scope.organization) != "", false)
    )
    error_message = "runner_scope.repositories and runner_scope.organization are mutually exclusive."
  }

  validation {
    condition = alltrue([
      for repository in var.runner_scope.repositories :
      can(regex("^[^/[:space:]]+/[^/[:space:]]+$", repository))
    ])
    error_message = "Every runner_scope.repositories entry must use non-empty owner/name form without whitespace."
  }

  validation {
    condition = (
      try(var.runner_scope.organization, null) == null ||
      try(trimspace(var.runner_scope.organization) == "", false) ||
      can(regex("^[A-Za-z0-9](?:[A-Za-z0-9-]{0,37}[A-Za-z0-9])?$", var.runner_scope.organization))
    )
    error_message = "runner_scope.organization must be null or a valid GitHub organization name."
  }
}
