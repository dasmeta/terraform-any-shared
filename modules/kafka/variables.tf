variable "name" {
  type        = string
  default     = "kafka"
  description = "App Name"
}

variable "chart_version" {
  type        = string
  default     = "21.4.6"
  description = "Bitnami Kafka chart version"
}

variable "namespace" {
  type        = string
  default     = "kafka"
  description = "Namespace"
}

variable "helm_set" {
  type        = any
  default     = []
  description = "Helm Set value"
}

variable "create_namespace" {
  type        = bool
  default     = true
  description = "Create Namespace"
}

variable "force_update" {
  type        = bool
  default     = true
  description = "Force Update"
}

variable "wait" {
  type        = bool
  default     = false
  description = "Wait"
}

variable "recreate_pods" {
  type        = bool
  default     = false
  description = "Recreate pods"
}

variable "deploy" {
  type        = number
  default     = 1
  description = "Deploy"
}

variable "resources_limits" {
  type        = any
  default     = {}
  description = "The resources limits for MongoDB containers"
}

variable "resources_requests" {
  type        = any
  default     = {}
  description = "The resources resources for MongoDB containers"
}

variable "kafka_cluster_0_name" {
  type    = string
  default = "local"
}

variable "kafka_cluster_0_bootstrapservers" {
  type    = string
  default = "kafka.kafka.svc.cluster.local:9092"
}

variable "kafka_cluster_0_zookeeper" {
  type    = string
  default = "kafka-zookeeper.kafka.svc.cluster.local:2181"
}

variable "kafka_ui_chart_version" {
  type    = string
  default = "0.6.2"
}

variable "enable_kafka_ui" {
  type    = bool
  default = true
}
