output "operator_helm_metadata" {
  value       = try(helm_release.operator[0].metadata, null)
  description = "Kiali operator Helm release metadata"
}

output "manifest" {
  value       = try(kubectl_manifest.this[0], null)
  description = "Kiali custom resource manifest"
}
