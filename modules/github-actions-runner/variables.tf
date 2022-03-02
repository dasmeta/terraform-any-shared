variable "runner_name" {
  type        = string
  description = "Runner Name"
  default     = "runner"
}

variable "personal_access_token" {
  type        = string
  description = "personal access token"
}

variable "repo_name" {
  type        = string
  description = "Repository Name"
  default     = "tutor-platform/ncet-infrastructure"
}

variable "kubectl_config_path" {
  type        = string
  default     = "~/.kube/config"
  description = "K8s config path"
}
