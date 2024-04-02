output "login_secrets" {
  value     = module.this.login_secrets
  sensitive = true
}

output "db_secrets" {
  value     = module.this.db_secrets
  sensitive = true
}

output "ssh_secrets" {
  value     = module.this.ssh_secrets
  sensitive = true
}
