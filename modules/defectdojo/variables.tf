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

variable "notifications" {
  type = object({
    enabled         = optional(bool)
    retain_state    = optional(bool, false)
    image           = optional(string, "python:3.12-slim@sha256:b18b261e1b4974b4f321451ad5251ded85abb22c2b8b262da527dda1d031ab30")
    api_url         = optional(string, "")
    engagement_ids  = optional(set(number), [])
    all_engagements = optional(bool, false)
    poll_schedule   = optional(string, "0 * * * *")
    digest_schedule = optional(string, "30 13 * * *")
    time_zone       = optional(string, "UTC")
    api_token_secret = optional(object({
      name = optional(string, "")
      key  = optional(string, "api-key")
    }), {})
    mysql = optional(object({
      create        = optional(bool, true)
      image         = optional(string, "mysql:8.4@sha256:a81d043930e51745522bd5c430961cf8286f0a23f0a9a2a6e0108f7ea71b0902")
      storage_size  = optional(string, "8Gi")
      storage_class = optional(string)
      host          = optional(string, "")
      port          = optional(number, 3306)
      database      = optional(string, "defectdojo_notifications")
      tls           = optional(bool, true)
      credentials_secret = optional(object({
        name         = optional(string, "")
        username_key = optional(string, "username")
        password_key = optional(string, "password")
      }), {})
      ca_secret = optional(object({
        name = optional(string, "")
        key  = optional(string, "ca.crt")
      }), {})
    }), {})
    channels = optional(object({
      slack_webhook_url = optional(string, "")
      teams_webhook_url = optional(string, "")
      opsgenie_api_key  = optional(string, "")
    }), {})
    channels_secret = optional(object({
      name         = optional(string, "")
      slack_key    = optional(string, "slack-url")
      teams_key    = optional(string, "teams-url")
      opsgenie_key = optional(string, "opsgenie-key")
    }), {})
    opsgenie_title_prefix = optional(string, "")
    opsgenie_region       = optional(string, "us")
    priority              = optional(string, "P2")
  })
  default     = {}
  nullable    = false
  description = "Critical main-branch Trivy notifications, automatically enabled by a configured channel or channels Secret when enabled is omitted; enabled=false explicitly disables and enabled=true requires complete valid configuration. Deliver to any combination of Slack, Teams and Opsgenie, using a dedicated managed MySQL outbox by default. Enabled scheduled jobs persist state and send real notifications. Requires Kubernetes >=1.27 and exactly one channel source: an existing channels_secret or direct channels values for at least one destination. Slack, Teams and Opsgenie are independent; one Opsgenie integration key authenticates findings and P5 summaries. Direct values use sensitive Helm settings but are stored in Terraform/Helm state; their owned Secret is removed with the worker release independently of retain_state. API token selection prefers an explicit Secret, otherwise matching-origin retention credentials, otherwise automatic application-account bootstrap. Source and bundled dependencies run in a public Python image; use mysql.create=false for an external MySQL and its existing credentials/CA Secrets. Choose engagement_ids or explicit all_engagements=true. Managed provisioning initializes tables. Disabling purges managed PVC/credentials by default and reenabling resends the current Critical backlog; explicitly set retain_state=true to preserve history. Uninstall uses the last installed hook policy, so apply retention changes while enabled before disabling. External MySQL and shared/caller API/channel Secrets are never purged. Notification-only API token Secrets are removed with their bootstrap without revoking the token. P5 Opsgenie summaries may page depending on integration rules."

  validation {
    condition = (
      length(var.notifications.opsgenie_title_prefix) <= 80 &&
      var.notifications.opsgenie_title_prefix == trimspace(var.notifications.opsgenie_title_prefix) &&
      !can(regex("[[:cntrl:]]", var.notifications.opsgenie_title_prefix))
    )
    error_message = "Opsgenie title prefix must be at most 80 characters, trimmed and without control characters."
  }

  # Terraform 1.3 validations must reference this variable only. Keep the
  # activation expression aligned with notifications_requested in notifications.tf.
  validation {
    condition = !(var.notifications.enabled != null ? var.notifications.enabled : (trimspace(var.notifications.channels_secret.name) != "" || anytrue([for value in values(var.notifications.channels) : trimspace(value) != ""]))) || (
      can(regex("^[^[:space:]]+$", var.notifications.image)) &&
      can(regex("^https?://[A-Za-z0-9]([A-Za-z0-9.-]*[A-Za-z0-9])?(:[0-9]{1,5})?/?$", lower(var.notifications.api_url)))
    )
    error_message = "Enabled notifications require a nonempty Python 3.12 container image and an HTTP(S) origin URL without credentials, paths, query parameters or fragments."
  }

  validation {
    condition = (
      length(var.notifications.engagement_ids) <= 100 &&
      alltrue([for id in var.notifications.engagement_ids : id > 0 && floor(id) == id]) &&
      ((var.notifications.enabled != null ? var.notifications.enabled : (trimspace(var.notifications.channels_secret.name) != "" || anytrue([for value in values(var.notifications.channels) : trimspace(value) != ""]))) ? (length(var.notifications.engagement_ids) > 0) != var.notifications.all_engagements : !(length(var.notifications.engagement_ids) > 0 && var.notifications.all_engagements))
    )
    error_message = "Use at most 100 positive integer engagement_ids or all_engagements=true, never both. Exactly one selector is required when notifications are enabled."
  }

  validation {
    condition = alltrue([
      for name in concat(var.notifications.api_token_secret.name == "" ? [] : [var.notifications.api_token_secret.name], var.notifications.channels_secret.name == "" ? [] : [var.notifications.channels_secret.name], var.notifications.mysql.create ? [] : [var.notifications.mysql.credentials_secret.name]) :
      (!(var.notifications.enabled != null ? var.notifications.enabled : (trimspace(var.notifications.channels_secret.name) != "" || anytrue([for value in values(var.notifications.channels) : trimspace(value) != ""]))) && name == "") || (
        length(name) <= 253 &&
        can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$", name)) &&
        alltrue([for label in split(".", name) : length(label) <= 63])
      )
    ])
    error_message = "Enabled external MySQL requires its credentials Secret. An optional explicit API token Secret, channels Secret and all other supplied names must be valid Kubernetes DNS subdomains; omit the API name for automatic token selection."
  }

  validation {
    condition = !(var.notifications.enabled != null ? var.notifications.enabled : (trimspace(var.notifications.channels_secret.name) != "" || anytrue([for value in values(var.notifications.channels) : trimspace(value) != ""]))) || (
      var.notifications.channels_secret.name != "" ?
      alltrue([for value in values(var.notifications.channels) : value == ""]) :
      anytrue([for value in values(var.notifications.channels) : trimspace(value) != ""]) &&
      alltrue([for value in values(var.notifications.channels) : value == "" || trimspace(value) != ""]) &&
      var.notifications.channels_secret.slack_key == "slack-url" &&
      var.notifications.channels_secret.teams_key == "teams-url" &&
      var.notifications.channels_secret.opsgenie_key == "opsgenie-key"
    )
    error_message = "Enabled notifications require exactly one channel source: channels_secret.name with no direct channels values, or direct channels for at least one destination with no channels_secret.name and default channel Secret keys. Slack, Teams and Opsgenie are independent; one Opsgenie integration key authenticates findings and P5 summaries. Omitted values must be empty, not whitespace-only."
  }

  validation {
    condition = var.notifications.mysql.ca_secret.name == "" || (
      var.notifications.mysql.tls &&
      length(var.notifications.mysql.ca_secret.name) <= 253 &&
      can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$", var.notifications.mysql.ca_secret.name)) &&
      alltrue([for label in split(".", var.notifications.mysql.ca_secret.name) : length(label) <= 63])
    )
    error_message = "The optional MySQL CA Secret requires tls=true and a valid Kubernetes DNS subdomain name."
  }

  validation {
    condition = alltrue([
      for key in [var.notifications.api_token_secret.key, var.notifications.mysql.credentials_secret.username_key, var.notifications.mysql.credentials_secret.password_key, var.notifications.mysql.ca_secret.key, var.notifications.channels_secret.slack_key, var.notifications.channels_secret.teams_key, var.notifications.channels_secret.opsgenie_key] :
      length(key) <= 253 && can(regex("^[A-Za-z0-9._-]+$", key))
    ])
    error_message = "Secret keys must be nonempty Kubernetes data keys of at most 253 characters."
  }

  validation {
    condition = (
      var.notifications.mysql.port >= 1 && var.notifications.mysql.port <= 65535 && floor(var.notifications.mysql.port) == var.notifications.mysql.port &&
      length(var.notifications.mysql.database) <= 64 && can(regex("^[A-Za-z0-9_]+$", var.notifications.mysql.database)) &&
      (!(var.notifications.enabled != null ? var.notifications.enabled : (trimspace(var.notifications.channels_secret.name) != "" || anytrue([for value in values(var.notifications.channels) : trimspace(value) != ""]))) || var.notifications.mysql.create || (
        length(var.notifications.mysql.host) <= 253 && can(regex("^[A-Za-z0-9]([A-Za-z0-9.-]*[A-Za-z0-9])?$", var.notifications.mysql.host))
      ))
    )
    error_message = "MySQL requires an integer port 1-65535; external MySQL requires a plain DNS/IPv4 host, and database names require 1-64 letters, digits or underscores."
  }

  validation {
    condition = !var.notifications.mysql.create || (
      var.notifications.mysql.host == "" && var.notifications.mysql.port == 3306 && var.notifications.mysql.tls &&
      var.notifications.mysql.credentials_secret.name == "" && var.notifications.mysql.ca_secret.name == "" &&
      var.notifications.mysql.credentials_secret.username_key == "username" && var.notifications.mysql.credentials_secret.password_key == "password" && var.notifications.mysql.ca_secret.key == "ca.crt"
    )
    error_message = "Managed MySQL derives host, port, credentials and CA references and requires TLS. Set mysql.create=false to supply external database connection/Secret fields."
  }

  validation {
    condition = (
      can(regex("^[^[:space:]]+$", var.notifications.mysql.image)) &&
      can(regex("^[1-9][0-9]*(Mi|Gi|Ti)$", var.notifications.mysql.storage_size)) &&
      (var.notifications.mysql.storage_class == null ? true : var.notifications.mysql.storage_class == "" || (
        length(var.notifications.mysql.storage_class) <= 253 && can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$", var.notifications.mysql.storage_class))
      ))
    )
    error_message = "MySQL image must be nonempty; storage_size must be a positive Mi/Gi/Ti quantity; optional storage_class must be empty or a Kubernetes DNS subdomain."
  }

  validation {
    condition = alltrue([
      for schedule in [var.notifications.poll_schedule, var.notifications.digest_schedule] :
      length(regexall("\\S+", schedule)) == 5 && alltrue([
        for index, field in regexall("\\S+", schedule) :
        can(regex("^(\\*|[0-9]+(-[0-9]+)?)(/[0-9]+)?(,(\\*|[0-9]+(-[0-9]+)?)(/[0-9]+)?)*$", field)) && alltrue([
          for item in split(",", field) :
          alltrue([for number in regexall("[0-9]+", split("/", item)[0]) : tonumber(number) >= try([0, 0, 1, 1, 0][index], 0) && tonumber(number) <= try([59, 23, 31, 12, 6][index], 0)]) &&
          (length(split("/", item)) == 1 ? true : try(tonumber(split("/", item)[1]) >= 1 && tonumber(split("/", item)[1]) <= [59, 23, 31, 12, 6][index], false)) &&
          (length(split("-", split("/", item)[0])) == 1 ? true : try(tonumber(split("-", split("/", item)[0])[0]) <= tonumber(split("-", split("/", item)[0])[1]), false))
        ])
      ])
    ])
    error_message = "Notification schedules must be five-field numeric cron expressions using valid field ranges, ascending ranges, lists and positive steps."
  }

  validation {
    condition = (
      can(regex("^[A-Za-z_+-]+(/[A-Za-z0-9_+-]+)*$", var.notifications.time_zone)) &&
      contains(["us", "eu"], var.notifications.opsgenie_region) && contains(["P1", "P2", "P3", "P4", "P5"], var.notifications.priority)
    )
    error_message = "Use an IANA time zone such as Asia/Yerevan or Etc/UTC, Opsgenie region us/eu, and priority P1-P5. Kubernetes validates that the time zone exists."
  }
}
