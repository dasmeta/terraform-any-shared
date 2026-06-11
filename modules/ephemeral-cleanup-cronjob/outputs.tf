output "release_name" {
  description = "Helm release name."
  value       = helm_release.this.name
}

output "release_namespace" {
  description = "Namespace where the Helm release is installed."
  value       = helm_release.this.namespace
}

output "release_status" {
  description = "Helm release status."
  value       = helm_release.this.status
}

output "job_name" {
  description = "CronJob name configured through base-cronjob."
  value       = var.job_name
}

output "helm_values" {
  description = "Rendered values passed to the base-cronjob Helm chart."
  value       = local.helm_values
  sensitive   = true
}
