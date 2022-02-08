
variable "rootpassword" {
  type    = string
  default = "root"
}

variable "pvcsize" {
  type    = string
  default = "8Gi"
}

variable "architecture" {
  type    = string
  default = "replicaset"
}
