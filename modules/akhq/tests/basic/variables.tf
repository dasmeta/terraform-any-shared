variable "kubeconfig_path" {
  type        = string
  default     = ""
  description = "Path to kubeconfig. Leave empty to use ~/.kube/config. Set when your shell only sets KUBECONFIG to a non-default file (e.g. after meta exec)."
}

variable "kafka_scram_username" {
  type        = string
  default     = ""
  description = "MSK SCRAM-SHA-512 username (passed through to the module). For real apply, set via terraform.tfvars (gitignored)."
}

variable "kafka_scram_password" {
  type        = string
  default     = ""
  sensitive   = true
  description = "MSK SCRAM-SHA-512 password. Never commit; use terraform.tfvars or TFC variables."
}
