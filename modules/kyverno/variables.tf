variable "name" {
  description = "The name of helm release."
  type        = string
  default     = "kyverno"
}

variable "chart_version" {
  type        = string
  default     = "3.5.1"
  description = "The app chart version to use"
}

variable "namespace" {
  description = "The namespace to install app helm. The doc recommends to have kyverno installed in its own namespace so before changing this check docs."
  type        = string
  default     = "kyverno"
}

variable "create_namespace" {
  type        = bool
  default     = true
  description = "Create namespace if requested"
}

variable "wait" {
  type        = bool
  default     = true
  description = "Whether wait to get the workload run successfully"
}

variable "atomic" {
  type        = bool
  default     = false
  description = "Whether auto rollback if helm install fails"
}

variable "resource_chart_version" {
  type        = string
  default     = "0.1.0"
  description = "The resource chart version to use"
}

variable "default_configs" {
  type = any
  default = {
    # we disabled the following controllers as seems no need for them for now, TODO: check what they do and maybe enable/configure this controllers
    backgroundController = {
      enabled : false
    }
    reportsController = {
      enabled : false
    }
    cleanupController = {
      enabled : false
    }
  }

  description = "The default values config to pass to helm chart. NOTE: that if you need to change just one field you will need to pass all configs and that field cha changed or you can pass you custom config within var.extra_configs"
}

variable "extra_configs" {
  type        = any
  default     = {}
  description = "Configs to pass and override helm values.yaml defaults and var.default_configs if needed more fine control. for more info check https://artifacthub.io/packages/helm/kyverno/kyverno?modal=values"
}

variable "policies" {
  type        = list(string)
  default     = []
  description = "Predefined kyverno rules to apply/enable. supported rule are \"bitnami-to-bitnamilegacy\""
}

variable "custom_policies" {
  type        = any
  default     = []
  description = "Custom kyverno rules to apply. The custom policies are list of objects. check for more details and example policies by link https://kyverno.io/policies"
}
