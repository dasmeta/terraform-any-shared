variable "release_name" {
  type        = string
  default     = "ephemeral-helm-cleanup"
  description = "Helm release name."

  validation {
    condition     = length(var.release_name) > 0
    error_message = "release_name must not be empty."
  }
}

variable "chart_repository" {
  type        = string
  default     = "https://dasmeta.github.io/helm"
  description = "Helm repository containing the base-cronjob chart. Set to null when chart_name is a local chart path."
}

variable "chart_name" {
  type        = string
  default     = "base-cronjob"
  description = "Helm chart name, or a local path to the base-cronjob chart."
}

variable "chart_version" {
  type        = string
  default     = "0.1.39"
  description = "base-cronjob chart version. Set to null when using a local chart path."
}

variable "namespace" {
  type        = string
  default     = "default"
  description = "Namespace where the Helm release is installed."

  validation {
    condition     = length(var.namespace) > 0
    error_message = "namespace must not be empty."
  }
}

variable "create_namespace" {
  type        = bool
  default     = false
  description = "Whether Helm should create the target namespace."
}

variable "job_name" {
  type        = string
  default     = "ephemeral-helm-cleanup"
  description = "CronJob name passed to base-cronjob."

  validation {
    condition     = length(var.job_name) > 0
    error_message = "job_name must not be empty."
  }
}

variable "schedule" {
  type        = string
  default     = "0 2 * * *"
  description = "Cron schedule for the cleanup job."

  validation {
    condition     = length(var.schedule) > 0
    error_message = "schedule must not be empty."
  }
}

variable "namespace_name_pattern" {
  type        = string
  default     = "ephemeral"
  description = "Substring used by the cleanup script to select namespaces containing Helm releases to uninstall."

  validation {
    condition     = length(var.namespace_name_pattern) > 0
    error_message = "namespace_name_pattern must not be empty."
  }
}

variable "image" {
  type = object({
    registry    = optional(string, "")
    repository  = optional(string, "alpine/k8s")
    tag         = optional(string, "1.20.15")
    pull_policy = optional(string, "IfNotPresent")
  })
  default     = {}
  description = "Container image settings for the cleanup job. The image must include kubectl and helm."

  validation {
    condition     = contains(["Always", "IfNotPresent", "Never"], var.image.pull_policy)
    error_message = "image.pull_policy must be one of Always, IfNotPresent, or Never."
  }
}

variable "dry_run" {
  type        = bool
  default     = false
  description = "When true, the script logs helm uninstall commands without executing them."
}

variable "suspend" {
  type        = bool
  default     = false
  description = "Whether to suspend future CronJob executions."
}

variable "concurrency_policy" {
  type        = string
  default     = "Forbid"
  description = "CronJob concurrency policy."

  validation {
    condition     = contains(["Allow", "Forbid", "Replace"], var.concurrency_policy)
    error_message = "concurrency_policy must be one of Allow, Forbid, or Replace."
  }
}

variable "successful_jobs_history_limit" {
  type        = number
  default     = 1
  description = "Number of successful finished jobs to retain."
}

variable "failed_jobs_history_limit" {
  type        = number
  default     = 1
  description = "Number of failed finished jobs to retain."
}

variable "starting_deadline_seconds" {
  type        = number
  default     = null
  description = "Optional deadline in seconds for starting a missed job."
}

variable "job_backoff_limit" {
  type        = number
  default     = 1
  description = "Number of retries before marking the job failed."
}

variable "ttl_seconds_after_finished" {
  type        = number
  default     = null
  description = "Optional TTL in seconds for finished jobs."
}

variable "restart_policy" {
  type        = string
  default     = "OnFailure"
  description = "Pod restart policy for the cleanup job."

  validation {
    condition     = contains(["Never", "OnFailure"], var.restart_policy)
    error_message = "restart_policy must be either Never or OnFailure."
  }
}

variable "service_account" {
  type = object({
    create      = optional(bool, true)
    name        = optional(string, "ephemeral-helm-cleanup")
    labels      = optional(map(string), {})
    annotations = optional(map(string), {})
  })
  default     = {}
  description = "ServiceAccount settings passed to base-cronjob."
}

variable "rbac" {
  type = object({
    create       = optional(bool, true)
    cluster_wide = optional(bool, true)
    name         = optional(string, "ephemeral-helm-cleanup-role")
    rules = optional(list(object({
      apiGroups = list(string)
      resources = list(string)
      verbs     = list(string)
    })), [])
  })
  default     = {}
  description = "RBAC settings passed to base-cronjob. Empty rules use the cleanup defaults."
}

variable "resources" {
  type = object({
    requests = object({
      cpu    = string
      memory = string
    })
    limits = object({
      cpu    = string
      memory = string
    })
  })
  default     = null
  description = "Optional CPU and memory requests and limits for the cleanup container."
}

variable "node_selector" {
  type        = map(string)
  default     = {}
  description = "Optional node selector for the cleanup pod."
}

variable "tolerations" {
  type = list(object({
    key                = optional(string)
    operator           = optional(string)
    value              = optional(string)
    effect             = optional(string)
    toleration_seconds = optional(number)
  }))
  default     = []
  description = "Optional tolerations for the cleanup pod."
}

variable "labels" {
  type = list(object({
    name  = string
    value = string
  }))
  default     = []
  description = "Labels passed to base-cronjob. The chart expects label entries with name and value fields."
}

variable "pod_annotations" {
  type        = map(string)
  default     = {}
  description = "Pod annotations passed to base-cronjob."
}

variable "extra_job_values" {
  type        = any
  default     = {}
  description = "Additional values merged into the generated base-cronjob job object."
}

variable "extra_values" {
  type        = any
  default     = {}
  description = "Additional values merged into the Helm values root."
}

variable "wait" {
  type        = bool
  default     = true
  description = "Whether Terraform waits for Helm release resources."
}

variable "atomic" {
  type        = bool
  default     = true
  description = "Whether Helm should roll back failed installs or upgrades."
}

variable "timeout" {
  type        = number
  default     = 300
  description = "Helm operation timeout in seconds."
}
