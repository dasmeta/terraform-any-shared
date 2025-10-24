output "release_name" {
  description = "Name of the Helm release"
  value       = helm_release.this.name
}

output "release_namespace" {
  description = "Namespace of the Helm release"
  value       = helm_release.this.namespace
}

output "release_version" {
  description = "Version of the Helm release"
  value       = helm_release.this.version
}

output "release_status" {
  description = "Status of the Helm release"
  value       = helm_release.this.status
}

output "ingress_hosts" {
  description = "List of ingress hosts"
  value       = var.ingress.enabled ? [for host in var.ingress.hosts : host.host] : []
}

output "deployment_name" {
  description = "Name of the Kubernetes deployment"
  value       = var.name
}
