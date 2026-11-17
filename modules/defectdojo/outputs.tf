output "helm_metadata" {
  value       = helm_release.this.metadata
  description = "DefectDojo Helm release metadata"
}

output "notifications" {
  value = local.notifications_enabled ? {
    release_name     = local.notifications_release_name
    namespace        = var.namespace
    state_namespace  = local.notifications_policy.namespace
    poll_cronjob     = "${local.notifications_release_name}-poll"
    digest_cronjob   = "${local.notifications_release_name}-digest"
    retain_state     = var.notifications.retain_state
    api_token_secret = local.notifications_api_token_secret
    api_token_source = local.notifications_api_token_source
    mysql_managed    = var.notifications.mysql.create
    mysql_release    = var.notifications.mysql.create ? local.notifications_mysql_release_name : null
    mysql_host       = local.notifications_mysql_host
    mysql_secret     = local.notifications_mysql_credentials_secret.name
  } : null
  description = "Nonsecret notification release, CronJob, effective API token Secret/key/source, MySQL connection/Secret references and state namespace identifiers; null when disabled."
}
