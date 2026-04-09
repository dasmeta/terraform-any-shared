output "release_name" {
  value       = helm_release.this.name
  description = "Helm release name."
}

output "release_namespace" {
  value       = helm_release.this.namespace
  description = "Kubernetes namespace of the release."
}

output "release_status" {
  value       = helm_release.this.status
  description = "Helm release status."
}

output "release_chart_version" {
  value       = helm_release.this.version
  description = "Chart version applied."
}

output "helm_metadata" {
  value       = helm_release.this.metadata
  description = "Helm release metadata."
}

output "ingress_hostnames" {
  value       = local.ingress_enabled ? [var.hostname] : []
  description = "Ingress hostnames when ingress is enabled."
}
