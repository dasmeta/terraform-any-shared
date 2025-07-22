// For provider
variable "cluster_name" {
  type = string
}

// For helm
variable "name" {
  type        = string
  default     = "renovate"
  description = "Helm release name"
}

variable "helm_version" {
  type        = string
  default     = "41.42.2"
  description = "Helm release version"
}

variable "namespace" {
  type        = string
  default     = "renovate"
  description = "Helm release namespace"
}

variable "branch_name" {
  type    = string
  default = "renovate-configure"
}

variable "platform" {
  type        = string
  default     = "gitlab"
  description = "Platform type of repository."
}

variable "endpoint" {
  type        = string
  default     = "https://gitlab.example.com/api/v4"
  description = "Custom endpoint to use."
}

variable "autodiscover" {
  type        = string
  default     = true
  description = "Autodiscover all repositories."
}

variable "schedule" {
  type        = string
  default     = "0 1 * * *"
  description = "Bot working shedule."
}

variable "token" {
  type        = string
  description = "GitLab Personal Access token"
}

variable "github_token" {
  type        = string
  description = "GitHub Personal Access token"
}

variable "host_rules" {
  description = "List of renovate [hostRules](https://docs.renovatebot.com/configuration-options/#hostrules)."
  type = list(object({
    hostType  = string
    token     = string
    matchHost = string
  }))
  default = []
}

variable "package_rules" {
  description = "List of renovate [packageRules](https://docs.renovatebot.com/configuration-options/#packagerules)."
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
