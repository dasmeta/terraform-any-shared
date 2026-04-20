output "release_name" {
  value       = helm_release.this.name
  description = "Name of the Argo CD Helm release."
}

output "release_namespace" {
  value       = helm_release.this.namespace
  description = "Namespace of the Argo CD Helm release."
}

output "release_status" {
  value       = helm_release.this.status
  description = "Status of the Argo CD Helm release."
}

output "release_chart_version" {
  value       = helm_release.this.version
  description = "Chart version used for the Argo CD Helm release."
}

output "helm_metadata" {
  value       = helm_release.this.metadata
  description = "Helm release metadata for the deployed Argo CD release."
}

output "admin_password_secret_name" {
  value       = "argocd-secret"
  description = "The Kubernetes Secret name used for Argo CD sensitive settings and (optionally) the admin password."
}

output "ingress_hostnames" {
  value       = local.ingress_enabled ? [var.hostname] : []
  description = "Ingress hostnames configured for Argo CD."
}
