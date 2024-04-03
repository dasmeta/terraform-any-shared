variable "data" {
  type = list(any)
  default = [{
    op_vault_name = "test"
    op_item       = "test-password"
    secret_key    = "test"
    }
  ]
  description = "OnePassword vault name and item name object. The Item should be in Vault"
}

//AWS
variable "aws_secret_name" {
  type        = string
  description = "AWS Secret name"
}

// Op login
variable "op_secret_key" {
  type        = string
  description = "OnePassword user secret key"
}

variable "op_password" {
  type        = string
  description = "OnePassword user password"
}

variable "op_account_address" {
  type        = string
  default     = "https://my.1password.com"
  description = "OnePassword account address"
}

variable "op_email" {
  type        = string
  description = "OnePassword user email"
}
