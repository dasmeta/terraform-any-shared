output "runner_scope_mode" {
  description = "Effective runner target mode: legacy_repository, repositories, or organization."
  value       = local.runner_scope_mode
}

output "runner_targets" {
  description = "Effective repository or organization targets."
  value       = local.effective_runner_targets
}

output "runner_resource_names" {
  description = "Kubernetes Runner resource names created by this module."
  value       = local.effective_runner_names
}
