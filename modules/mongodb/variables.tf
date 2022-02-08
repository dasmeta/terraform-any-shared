variable "name" {
  type        = string
  default     = "mongodb"
  description = "mongodb helm release name"
}

variable "rootpassword" {
  type        = string
  default     = "root"
  description = "root user password"
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
