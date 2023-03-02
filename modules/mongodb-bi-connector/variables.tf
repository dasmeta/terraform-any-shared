variable "name" {
  type        = string
  default     = "mongodb-bi-connector"
  description = "Release name."
}

variable "namespace" {
  type        = string
  default     = "default"
  description = "Release namespace."
}

variable "mongodb_username" {
  type        = string
  description = "MongoDB username."
}

variable "mongodb_password" {
  type        = string
  description = "MongoDB password."
}

variable "mongodb_uri" {
  type        = string
  description = "MongoDB URI."
}
