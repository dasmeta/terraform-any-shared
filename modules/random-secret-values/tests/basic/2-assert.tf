output "application_key_length" {
  value = length(nonsensitive(module.values.values.application_key))
}

output "password_matches_database_password" {
  value = nonsensitive(module.values.values.password) == nonsensitive(module.values.values.database_password)
}
