variable "data" {
  type = any
  default = [
    {
      op_vault_name = "test"
      op_item       = "test-password"
    }
  ]
}

// Op login 
variable "op_secret_key" {
  type = string
}

variable "op_password" {
  type = string
}

variable "op_account_address" {
  type    = string
  default = "https://my.1password.com"
}

variable "op_email" {
  type = string
}
