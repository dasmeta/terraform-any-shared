output "secret_data" {
  description = "The fetched secret data"
  value       = data.secretsmanager_database_credentials.database_credentials
}
