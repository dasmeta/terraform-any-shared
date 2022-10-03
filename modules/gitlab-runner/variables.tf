variable "runner_name" {
  type        = string
  description = "Runner Name"
  default     = "gitlab-runner"
}

variable "runnerToken" {
  type        = string
  description = "Gitlab Runner Token"
  default     = ""
}

variable "runnerRegistrationToken" {
  type        = string
  description = "gitlab runner registration token"
  default     = ""
}

variable "gitlab_access_token" {
  type        = string
  description = "Personal Access Token"
  default     = ""
}

variable "kubectl_config_path" {
  type        = string
  description = "K8s config path"
  default     = "~/.kube/config"
}

variable "namespace" {
  type        = string
  description = "Namespace name"
  default     = "gitlab-runner"
}

variable "name" {
  type        = string
  description = "name"
  default     = "gitlab-runner"
}
