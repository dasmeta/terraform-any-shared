variable "name" {
  type        = string
  description = "Service names"
}

variable "namespace" {
  type        = string
  description = "Namespace"
}

variable "cluster_name" {
  type        = string
  description = "Cluster name"
}

variable "helm_values" {
  type        = any
  description = "Values which is overwrite chart defaults"
}

variable "alarms" {
  type = object({
    enabled       = optional(bool, true)
    sns_topic     = string
    custom_values = optional(any, {})
  })
  description = "Alarms enabled by default you need set sns topic name for send alarms for customize alarms threshold use custom_values"
}
