// For provider
variable "cluster_name" {
  type = string
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

variable "branch_name" {
  type    = string
  default = "renovate-configure"
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
  description = "GitLab Personal Access token"
}

variable "github_token" {
  type        = string
  description = "GitHub Personal Access token"
}
