output "helm_metadata" {
  value       = helm_release.this.metadata
  description = "Renovate Helm release metadata"
}
