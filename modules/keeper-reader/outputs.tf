output "login_secrets" {
  value = { for uid, module in module.login_secrets : uid => module.secret_data }
}

output "db_secrets" {
  value = { for uid, module in module.db_secrets : uid => module.secret_data }
}

output "ssh_secrets" {
  value = { for uid, module in module.ssh_secrets : uid => module.secret_data }
}

output "all_secrets" {
  value = merge(
    { for uid, module in module.login_secrets : uid => module.secret_data },
    { for uid, module in module.db_secrets : uid => module.secret_data },
    { for uid, module in module.ssh_secrets : uid => module.secret_data }
  )
}
