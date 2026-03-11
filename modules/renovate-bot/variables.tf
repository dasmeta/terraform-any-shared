# Helm release

variable "name" {
  description = "The name of the Helm release."
  type        = string
  default     = "renovate"
}

variable "chart_version" {
  description = "The Renovate Helm chart version to use."
  type        = string
  default     = "46.52.2"
}

variable "namespace" {
  description = "The Kubernetes namespace to install Renovate."
  type        = string
  default     = "renovate"
}

variable "create_namespace" {
  description = "Create the namespace if it does not exist."
  type        = bool
  default     = true
}

variable "wait" {
  description = "Wait for the release to be deployed successfully."
  type        = bool
  default     = true
}

variable "atomic" {
  description = "If set, the installation process will be rolled back on failure."
  type        = bool
  default     = false
}

variable "helm_extra_configs" {
  description = "Additional or override values for the Helm chart. Merged on top of default values. See Renovate Helm chart documentation."
  type        = any
  default     = {}
}

# Renovate bot config (self-hosted). See https://docs.renovatebot.com/self-hosted-configuration/
# Pass only the keys you want to override; defaults apply for the rest.

variable "renovate" {
  description = "Renovate bot configuration (keys match Renovate's config format). Override only the keys you need (e.g. platform = \"github\"); the rest use defaults."
  type = object({
    configs = object({
      platform         = optional(string, "gitlab")
      endpoint         = optional(string, "https://gitlab.com/api/v4")
      token            = optional(string, "")
      github_token     = optional(string, "")
      schedule         = optional(string, "0 1 * * *")
      autodiscover     = optional(bool, true)
      onboardingBranch = optional(string, "renovate-configure")
      hostRules = optional(list(object({
        matchHost = string
        token     = string
        hostType  = string
      })), [])
      packageRules = optional(list(object({
        matchDatasources            = optional(list(string))
        matchPackageNames           = optional(list(string))
        matchPackagePatterns        = optional(list(string))
        matchPaths                  = optional(list(string))
        extends                     = optional(list(string))
        registryUrls                = optional(list(string))
        groupName                   = optional(string)
        schedule                    = optional(string)
        dependencyDashboardApproval = optional(bool)
      })), [])
    })
  })
  default   = { configs = {} }
  sensitive = true
}

variable "renovate_extra_configs" {
  description = "Extra Renovate config options not covered by renovate.configs (e.g. onboarding, requireConfig). Merged into the final config. See https://docs.renovatebot.com/self-hosted-configuration/"
  type        = any
  default     = {}
}
