// For provider

variable "cluster_host" {
  type        = string
  description = "Cluster host for helm provider"
}

variable "cluster_ca_certificate" {
  type        = string
  description = "Cluster certificate for helm provider"
}

variable "cluster_token" {
  type        = string
  description = "Cluster token for helm provider"
}


// For helm
variable "name" {
  type        = string
  default     = "renovate"
  description = "Helm release name"
}

variable "namespace" {
  type        = string
  default     = "renovate"
  description = "Helm release namespace"
}

variable "platform" {
  type        = string
  default     = "gitlab"
  description = "Platform type of repository."
}

variable "endpoint" {
  type        = string
  default     = "https://gitlab.example.com/api/v4"
  description = "Custom endpoint to use."
}

variable "autodiscover" {
  type        = string
  default     = true
  description = "Autodiscover all repositories."
}

variable "schedule" {
  type        = string
  default     = "0 1 * * *"
  description = "Bot working shedule."
}

variable "token" {
  type        = string
  description = "Personal Access token"
}
