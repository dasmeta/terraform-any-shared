output "runner_scope_mode" {
  description = "Effective runner target mode: legacy_repository, repositories, organization, or scale_set."
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

output "deployment_mode" {
  description = "Selected runner deployment implementation: legacy or scale_set."
  value       = var.deployment_mode
}

output "runner_scale_set_name" {
  description = "Official runner scale-set workflow label when deployment_mode is scale_set; otherwise null."
  value       = local.uses_scale_set ? var.scale_set.runner_scale_set_name : null
}
