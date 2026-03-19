output "helm_metadata" {
  value       = helm_release.this.metadata
  description = "DefectDojo Helm release metadata"
}
