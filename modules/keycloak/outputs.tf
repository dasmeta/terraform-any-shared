output "release_name" {
  value       = helm_release.this.name
  description = "Name of the Keycloak Helm release."
}

output "release_namespace" {
  value       = helm_release.this.namespace
  description = "Namespace of the Keycloak Helm release."
}

output "release_status" {
  value       = helm_release.this.status
  description = "Status of the Keycloak Helm release."
}

output "release_chart_version" {
  value       = helm_release.this.version
  description = "Chart version used for the Keycloak Helm release."
}

output "helm_metadata" {
  value       = helm_release.this.metadata
  description = "Helm release metadata for the deployed Keycloak release."
}

output "admin_password_secret_name" {
  value       = local.admin_password_secret_name
  description = "The Kubernetes Secret name used for the admin password."
}

output "database_password_secret_name" {
  value       = nonsensitive(local.database_password_secret_name)
  description = "The Kubernetes Secret name used for the database password."
}

output "ingress_hostnames" {
  value       = local.ingress_enabled ? [var.hostname] : []
  description = "Ingress hostnames configured for Keycloak."
}
