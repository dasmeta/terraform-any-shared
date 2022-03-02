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
