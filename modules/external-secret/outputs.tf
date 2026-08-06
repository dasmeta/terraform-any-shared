output "external_secret_name" {
  value       = var.name
  description = "ExternalSecret resource name."
}

output "target_secret_name" {
  value       = var.target.name
  description = "Kubernetes Secret name managed by the ExternalSecret."
}
