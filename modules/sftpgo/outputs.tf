output "helm_release_name" {
  description = "The SFTPGo Helm release name."
  value       = helm_release.this.name
}

output "helm_release_namespace" {
  description = "The SFTPGo Helm release namespace."
  value       = helm_release.this.namespace
}

output "helm_release_status" {
  description = "The SFTPGo Helm release status."
  value       = helm_release.this.status
}

output "helm_release_version" {
  description = "The deployed SFTPGo Helm chart version."
  value       = helm_release.this.version
}

output "sftp_service_name" {
  description = "The optional SFTP-only Kubernetes Service name, or null when disabled."
  value       = try(kubernetes_service_v1.sftp[0].metadata[0].name, null)
}

output "sftp_service_namespace" {
  description = "The optional SFTP-only Kubernetes Service namespace, or null when disabled."
  value       = try(kubernetes_service_v1.sftp[0].metadata[0].namespace, null)
}

output "sftp_service_port" {
  description = "The optional SFTP-only Kubernetes Service port, or null when disabled."
  value       = try(kubernetes_service_v1.sftp[0].spec[0].port[0].port, null)
}

output "sftp_service_load_balancer_hostname" {
  description = "The optional SFTP-only Service load balancer hostname, or null until unavailable or disabled."
  value       = try(kubernetes_service_v1.sftp[0].status[0].load_balancer[0].ingress[0].hostname, null)
}
