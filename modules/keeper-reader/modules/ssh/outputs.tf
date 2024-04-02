output "secret_data" {
  description = "The fetched secret data"
  value       = data.secretsmanager_ssh_keys.ssh
}
