variable "secrets" {
  description = "List of secrets to fetch from Keeper Security"
  type = list(object({
    secret_type = string
    uid         = string
  }))

  validation {
    condition     = alltrue([for s in var.secrets : contains(["login", "db", "ssh"], s.secret_type)])
    error_message = "Currently we support only 3 types of secrets: 'login', 'db', or 'ssh'. Please ensure each 'secret_type' is set to one of these types."
  }
}

variable "keeper_credentials" {
  type        = string
  description = "Keeper credentials' file in JSON format"
}
