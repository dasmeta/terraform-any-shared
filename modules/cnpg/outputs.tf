output "cluster_name" {
  value       = var.name
  description = "CloudNativePG Cluster name."
}

output "namespace" {
  value       = var.namespace
  description = "Namespace containing the Cluster and its generated Services."
}

output "database_name" {
  value       = var.database.name
  description = "Initial application database name."
}

output "database_owner" {
  value       = var.database.owner
  description = "Initial application database owner role."
}

output "rw_service_name" {
  value       = "${var.name}-rw"
  description = "CNPG read/write Service name for application traffic."
}

output "rw_service_hostname" {
  value       = "${var.name}-rw.${var.namespace}.svc"
  description = "Cluster-local CNPG read/write Service hostname for application traffic."
}

output "ro_service_name" {
  value       = "${var.name}-ro"
  description = "CNPG read-only Service name for replicas only."
}

output "ro_service_hostname" {
  value       = "${var.name}-ro.${var.namespace}.svc"
  description = "Cluster-local CNPG read-only Service hostname for replicas only."
}

output "r_service_name" {
  value       = "${var.name}-r"
  description = "CNPG read Service name that can route to any ready instance."
}

output "r_service_hostname" {
  value       = "${var.name}-r.${var.namespace}.svc"
  description = "Cluster-local CNPG read Service hostname that can route to any ready instance."
}

output "port" {
  value       = 5432
  description = "PostgreSQL port exposed by the CNPG read/write Service."
}
