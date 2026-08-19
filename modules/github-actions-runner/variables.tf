variable "runner_name" {
  type        = string
  description = "Runner Name"
  default     = "runner"
}

variable "deployment_mode" {
  type        = string
  default     = "legacy"
  description = "Runner deployment implementation. Use legacy to preserve the existing controller or scale_set for the official GitHub ARC chart path."

  validation {
    condition     = contains(["legacy", "scale_set"], var.deployment_mode)
    error_message = "deployment_mode must be legacy or scale_set."
  }
}

variable "scale_set" {
  type = object({
    github_config_url        = optional(string, null)                      # GitHub organization or repository HTTPS URL served by this scale set.
    runner_scale_set_name    = optional(string, "github-runner-scale-set") # Workflow runs-on label and official runner scale-set name.
    min_runners              = optional(number, 1)                         # Minimum idle ephemeral runners retained for new jobs.
    max_runners              = optional(number, 3)                         # Maximum total ephemeral runners that GitHub may request.
    controller_chart_version = optional(string, "0.14.2")                  # Official gha-runner-scale-set-controller chart version.
    chart_version            = optional(string, "0.14.2")                  # Official gha-runner-scale-set chart version.
  })
  default     = {}
  description = "Official GitHub ARC runner scale-set configuration. Required only when deployment_mode is scale_set."

  validation {
    condition = var.deployment_mode != "scale_set" || (
      try(trimspace(var.scale_set.github_config_url), "") != "" &&
      can(regex("^https://github\\.com/[^/[:space:]]+(/[^/[:space:]]+)?/?$", var.scale_set.github_config_url))
    )
    error_message = "scale_set.github_config_url must be an HTTPS GitHub organization or repository URL when deployment_mode is scale_set."
  }

  validation {
    condition = (
      length(var.scale_set.runner_scale_set_name) <= 50 &&
      can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.scale_set.runner_scale_set_name))
    )
    error_message = "scale_set.runner_scale_set_name must be a lowercase Kubernetes DNS label of at most 50 characters."
  }

  validation {
    condition = (
      var.scale_set.min_runners >= 0 &&
      var.scale_set.max_runners >= var.scale_set.min_runners &&
      floor(var.scale_set.min_runners) == var.scale_set.min_runners &&
      floor(var.scale_set.max_runners) == var.scale_set.max_runners
    )
    error_message = "scale_set.min_runners and scale_set.max_runners must be non-negative integers, and max_runners must be at least min_runners."
  }

  validation {
    condition = (
      try(trimspace(var.scale_set.controller_chart_version) != "", false) &&
      try(trimspace(var.scale_set.chart_version) != "", false)
    )
    error_message = "scale_set controller and runner chart versions must be non-empty strings."
  }
}

variable "personal_access_token" {
  type        = string
  description = "GitHub personal access token used by the selected controller path. Set to null when github_auth_secret_name is provided."
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
  description = "Kubernetes namespace in which the selected runner controller and runner resources are installed."
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
