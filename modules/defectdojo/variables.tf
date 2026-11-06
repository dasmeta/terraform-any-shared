variable "name" {
  description = "The name of the Helm release."
  type        = string
  default     = "defectdojo"
}

variable "chart_version" {
  description = "The DefectDojo Helm chart version to use."
  type        = string
  default     = "1.9.64"
}

variable "namespace" {
  description = "The Kubernetes namespace to install DefectDojo."
  type        = string
  default     = "defectdojo"
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

variable "default_configs" {
  description = "Default values to pass to the Helm chart. Override specific fields via custom_configs."
  type        = any
  default = {
    createSecret           = true
    createValkeySecret     = true
    createPostgresqlSecret = true
  }
}

variable "custom_configs" {
  description = "Additional or override values for the Helm chart. Merged on top of default_configs. See https://artifacthub.io/packages/helm/defectdojo/defectdojo?modal=values"
  type        = any
  default     = {}
}

variable "retention" {
  type = object({
    enabled   = optional(bool, false)
    days      = optional(number, 30)
    schedule  = optional(string, "17 2 * * *")
    time_zone = optional(string, "Etc/UTC")
    api_url   = optional(string, "")
    api_token_secret = optional(object({
      create = optional(bool, false)
      name   = optional(string, "")
      key    = optional(string, "api-key")
    }), {})
    engagement_ids         = optional(set(number), [])
    engagement_names       = optional(set(string), [])
    all_engagements        = optional(bool, false)
    protected_branches     = optional(set(string), [])
    protected_environments = optional(set(string), [])
    max_tests_per_run      = optional(number, 10)
  })
  default     = {}
  nullable    = false
  description = "Opt-in cleanup of inactive completed Trivy feature Tests without active findings. Select exactly one of engagement_ids, exact unique engagement_names or explicit all_engagements. Requires Kubernetes >=1.27 and API base URL. Supply an existing API token Secret or enable api_token_secret.create to bootstrap one from the chart account. See README for permissions and concurrency limitations."

  validation {
    condition     = var.retention.days >= 1 && var.retention.days <= 3650 && floor(var.retention.days) == var.retention.days
    error_message = "retention.days must be an integer between 1 and 3650."
  }

  validation {
    condition     = var.retention.max_tests_per_run >= 1 && var.retention.max_tests_per_run <= 100 && floor(var.retention.max_tests_per_run) == var.retention.max_tests_per_run
    error_message = "retention.max_tests_per_run must be an integer between 1 and 100."
  }

  validation {
    condition     = length(var.retention.engagement_ids) <= 100 && alltrue([for id in var.retention.engagement_ids : id > 0 && floor(id) == id])
    error_message = "retention.engagement_ids must contain at most 100 positive integer IDs."
  }

  validation {
    condition     = length(var.retention.engagement_names) <= 100 && alltrue([for name in var.retention.engagement_names : length(trimspace(name)) > 0 && length(name) <= 512 && length(regexall("[\\x00-\\x1f\\x7f]", name)) == 0])
    error_message = "retention.engagement_names must contain at most 100 nonempty exact names of up to 512 characters without control characters."
  }

  validation {
    condition = var.retention.enabled ? sum([
      length(var.retention.engagement_ids) > 0 ? 1 : 0,
      length(var.retention.engagement_names) > 0 ? 1 : 0,
      var.retention.all_engagements ? 1 : 0,
      ]) == 1 : sum([
      length(var.retention.engagement_ids) > 0 ? 1 : 0,
      length(var.retention.engagement_names) > 0 ? 1 : 0,
      var.retention.all_engagements ? 1 : 0,
    ]) <= 1
    error_message = "Use exactly one engagement selector when enabled: engagement_ids, engagement_names or all_engagements=true. Empty selectors never mean all."
  }

  validation {
    condition = !var.retention.enabled || (
      can(regex("^https?://[^/?#@]+/?$", var.retention.api_url)) &&
      ((var.retention.api_token_secret.create && var.retention.api_token_secret.name == "") || (
        length(var.retention.api_token_secret.name) <= 253 &&
        can(regex("^[a-z0-9]([-a-z0-9.]*[a-z0-9])?$", var.retention.api_token_secret.name))
      )) &&
      length(var.retention.api_token_secret.key) <= 253 &&
      can(regex("^[A-Za-z0-9._-]+$", var.retention.api_token_secret.key))
    )
    error_message = "Enabled retention requires an HTTP(S) origin URL and valid Secret key. A valid Secret name is required unless create=true derives it automatically."
  }

  validation {
    condition     = length(regexall("\\S+", var.retention.schedule)) == 5 && length(trimspace(var.retention.time_zone)) > 0
    error_message = "Use a five-field cron schedule and a nonempty IANA time zone such as Etc/UTC."
  }

  validation {
    condition = alltrue([
      for patterns in [var.retention.protected_branches, var.retention.protected_environments] :
      length(patterns) <= 100 && alltrue([for pattern in patterns : length(trimspace(pattern)) > 0 && length(pattern) <= 200])
    ])
    error_message = "Each protection list may contain at most 100 nonempty patterns of up to 200 characters."
  }
}
