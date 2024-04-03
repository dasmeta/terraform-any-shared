variable "secrets" {
  description = "List of secrets to fetch from Keeper Security"
  type = list(object({
    secret_type = string # Record type for each one
    uid         = string # UID of a specific secret record
  }))

  validation {
    condition     = alltrue([for s in var.secrets : contains(["login", "db", "ssh"], s.secret_type)])
    error_message = "Currently we support only 3 types of secrets: 'login', 'db', or 'ssh'. Please ensure each 'secret_type' is set to one of these types."
  }
}
