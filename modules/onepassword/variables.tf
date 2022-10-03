variable "data" {
  type = any
  default = [
    {
      op_vault_name = "test"
      op_item       = "test-password"
    }
  ]
  description = "OnePassword vault,item name. The Item should be in Vault"
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
