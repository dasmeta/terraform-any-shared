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

variable "custom_configs" {
  description = "Additional or override values for the Helm chart. Merged on top of default values. See Renovate Helm chart documentation."
  type        = any
  default     = {}
}

# Renovate bot config (self-hosted). See https://docs.renovatebot.com/self-hosted-configuration/

variable "platform" {
  description = "Platform type (e.g. gitlab, github)."
  type        = string
  default     = "gitlab"
}

variable "endpoint" {
  description = "Platform API endpoint (e.g. https://gitlab.com/api/v4)."
  type        = string
  default     = "https://gitlab.com/api/v4"
}

variable "token" {
  description = "Platform Personal Access token (GitLab/GitHub etc.)."
  type        = string
  sensitive   = true
}

variable "github_token" {
  description = "GitHub Personal Access token (for fetching release notes etc.)."
  type        = string
  sensitive   = true
}

variable "autodiscover" {
  description = "Autodiscover all repositories the token can access."
  type        = bool
  default     = true
}

variable "onboarding_branch" {
  description = "Branch name used for onboarding PRs (e.g. renovate-configure)."
  type        = string
  default     = "renovate-configure"
}

variable "schedule" {
  description = "Cron schedule for the Renovate CronJob (e.g. '0 1 * * *' for daily at 01:00)."
  type        = string
  default     = "0 1 * * *"
}

variable "host_rules" {
  description = "List of Renovate hostRules (private registries, auth). See https://docs.renovatebot.com/configuration-options/#hostrules."
  type = list(object({
    matchHost = string
    token     = string
    hostType  = string
  }))
  default = []
}

variable "package_rules" {
  description = "List of Renovate packageRules. See https://docs.renovatebot.com/configuration-options/#packagerules."
  type = list(object({
    matchDatasources            = optional(list(string))
    matchPackageNames           = optional(list(string))
    matchPackagePatterns        = optional(list(string))
    matchPaths                  = optional(list(string))
    extends                     = optional(list(string))
    registryUrls                = optional(list(string))
    groupName                   = optional(string)
    schedule                    = optional(string)
    dependencyDashboardApproval = optional(bool)
  }))
  default = []
}

variable "extra_config" {
  description = "Optional JSON object merged into Renovate config. Use for self-hosted-only options (e.g. allowScripts, allowedCommands) or shared defaults. See https://docs.renovatebot.com/self-hosted-configuration/"
  type        = string
  default     = "{}"
}
