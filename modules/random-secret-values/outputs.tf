output "values" {
  value       = local.values
  description = "Complete generated credential payload for a dedicated secret-store consumer."
  sensitive   = true

  precondition {
    condition     = local.unique_keys
    error_message = "generated_values, static_values, and aliases must not define the same destination key."
  }

  precondition {
    condition     = local.valid_aliases
    error_message = "Each alias source must refer to a generated_values or static_values key; aliases cannot reference aliases."
  }
}

output "keys" {
  value       = local.result_key_names
  description = "Non-sensitive sorted keys in the generated values map."
}
