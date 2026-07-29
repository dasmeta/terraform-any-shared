output "namespace_name" {
  description = "Name of the managed Kubernetes namespace."
  value       = kubernetes_namespace_v1.this.metadata[0].name
}

output "namespace_id" {
  description = "Terraform provider ID of the managed Kubernetes namespace."
  value       = kubernetes_namespace_v1.this.id
}

output "namespace_uid" {
  description = "Kubernetes-assigned immutable UID of the managed namespace."
  value       = kubernetes_namespace_v1.this.metadata[0].uid
}
