output "kyverno_helm_metadata" {
  value       = helm_release.this.metadata
  description = "Helm release metadata"
}

output "resources_helm_metadata" {
  value       = helm_release.resources.metadata
  description = "Helm release metadata"
}
