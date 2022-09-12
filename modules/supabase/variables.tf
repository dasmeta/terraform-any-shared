variable "namespace" {
  type    = string
  default = "supabase"
}

variable "ANON_KEY" {
  type    = string
  default = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlhdCI6MTY0MDMwMDQwMCwiZXhwIjoxNzk4MDY2ODAwfQ.JaEiRNdyxX3Pk6XupxauDazXeadLTgTHz5cV7joUrQE"
}

variable "SERVICE_KEY" {
  type    = string
  default = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoic2VydmljZV9yb2xlIiwiaWF0IjoxNjQwMzAwNDAwLCJleHAiOjE3OTgwNjY4MDB9.sUJPVrhMsSaLgizyCWIgNOIRmjavxDB4Lm3hzb4dC5U"
}

variable "JWT_SECRET" {
  type    = string
  default = "your-super-secret-jwt-token-with-at-least-32-characters-long"
}

variable "SMTP_HOST" {
  type    = string
  default = "mail"
}

variable "SMTP_ADMIN_EMAIL" {
  type    = string
  default = "admin@example.com"
}

variable "SMTP_USER" {
  type    = string
  default = "mail_user"
}

variable "SMTP_PASS" {
  type    = string
  default = "mail_password"
}

variable "SMTP_SENDER_NAME" {
  type    = string
  default = "sender"
}

variable "DB_PASSWORD" {
  type    = string
  default = "yXmwewewddjijdFfPLMEvhXaQH"
}
