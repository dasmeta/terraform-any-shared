output "release_name" {
  value       = helm_release.this.name
  description = "Name of the Authentik Helm release."
}

output "release_namespace" {
  value       = helm_release.this.namespace
  description = "Namespace of the Authentik Helm release."
}

output "release_status" {
  value       = helm_release.this.status
  description = "Helm-reported Authentik release status."
}

output "release_chart_version" {
  value       = helm_release.this.version
  description = "Chart version used by the Authentik Helm release."
}

output "server_service_name" {
  value       = "${var.name}-server"
  description = "Internal Authentik server Service name for separately managed ingress."
}

output "server_service_http_port" {
  value       = 80
  description = "Internal Authentik server Service HTTP port for separately managed ingress."
}
