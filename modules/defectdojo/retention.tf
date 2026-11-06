locals {
  retention_policy = {
    api_url                = var.retention.api_url
    days                   = var.retention.days
    engagement_ids         = [for id in sort([for id in var.retention.engagement_ids : tostring(id)]) : tonumber(id)]
    engagement_names       = sort(tolist(var.retention.engagement_names))
    all_engagements        = var.retention.all_engagements
    protected_branches     = sort(tolist(var.retention.protected_branches))
    protected_environments = sort(tolist(var.retention.protected_environments))
    max_tests_per_run      = var.retention.max_tests_per_run
  }

  retention_chart_files = sort([
    for filename in fileset("${path.module}/charts/retention", "**") : filename
    if length(regexall("(^|/)__pycache__(/|$)|\\.pyc$", filename)) == 0
  ])
}

resource "helm_release" "retention" {
  count = var.retention.enabled ? 1 : 0

  name      = "${var.name}-retention"
  namespace = var.namespace
  chart     = "${path.module}/charts/retention"
  version   = "0.1.0"
  atomic    = var.atomic
  wait      = var.wait

  values = [jsonencode({
    schedule = var.retention.schedule
    timeZone = var.retention.time_zone
    apiTokenSecret = {
      name = local.retention_token_secret_name
      key  = var.retention.api_token_secret.key
    }
    policy          = local.retention_policy
    contentChecksum = sha256(join("", [for filename in local.retention_chart_files : filesha256("${path.module}/charts/retention/${filename}")]))
  })]

  depends_on = [helm_release.this, helm_release.retention_bootstrap]

  lifecycle {
    precondition {
      condition     = length(var.name) <= 42
      error_message = "When retention is enabled, name must be at most 42 characters to leave room for the CronJob suffix."
    }
  }
}
