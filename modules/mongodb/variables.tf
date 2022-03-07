variable "name" {
  type        = string
  default     = "mongodb"
  description = "mongodb helm release name"
}

variable "root_password" {
  type        = string
  default     = "root"
  description = "root user password"
}

variable "replicaset_key" {
  type        = string
  default     = ""
  description = "Key used for authentication in the replicaset (only when architecture=replicaset)"
}

variable "existing_secret" {
  type        = string
  default     = ""
  description = "Existing secret with MongoDB(®) credentials (keys: mongodb-password, mongodb-root-password, mongodb-replica-set-key)"
}

variable "pvcsize" {
  type        = string
  default     = "8Gi"
  description = "persistence volume size"
}

variable "architecture" {
  type        = string
  default     = "replicaset"
  description = "architecture can be replicaset or standalone"
}

variable "service_type" {
  type        = string
  default     = "NodePort"
  description = "Service Type"
}

variable "resources_limits" {
  type = any
  default = {
    cpu    = "500m"
    memory = "128Mi"
  }
  description = "The resources limits for MongoDB containers"
}

variable "resources_requests" {
  type = any
  default = {
    cpu    = "250m"
    memory = "64Mi"
  }
  description = "The resources resources for MongoDB containers"
}
