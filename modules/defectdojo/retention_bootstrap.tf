locals {
  retention_token_secret_name = coalesce(var.retention.api_token_secret.name, "${var.name}-retention")

  # Follow the upstream chart's fullname helper, including top-level overrides.
  retention_application_values = merge(var.default_configs, var.custom_configs)
  retention_application_name   = coalesce(try(local.retention_application_values.nameOverride, null), "defectdojo")
  retention_application_base   = length(split(local.retention_application_name, var.name)) > 1 ? var.name : "${var.name}-${local.retention_application_name}"
  retention_application_fullname = trimsuffix(substr(coalesce(
    try(local.retention_application_values.fullnameOverride, null),
    local.retention_application_base
  ), 0, 63), "-")

  retention_bootstrap_files = sort([
    for filename in fileset("${path.module}/charts/retention-bootstrap", "**") : filename
    if length(regexall("(^|/)__pycache__(/|$)|\\.pyc$", filename)) == 0
  ])
}

resource "helm_release" "retention_bootstrap" {
  count = var.retention.enabled && var.retention.api_token_secret.create ? 1 : 0

  name      = "${var.name}-token"
  namespace = var.namespace
  chart     = "${path.module}/charts/retention-bootstrap"
  version   = "0.1.0"
  wait      = true
  atomic    = var.atomic
  timeout   = 900

  values = [jsonencode({
    apiUrl             = var.retention.api_url
    sourceFullname     = local.retention_application_fullname
    applicationRelease = var.name
    targetSecret = {
      name = local.retention_token_secret_name
      key  = var.retention.api_token_secret.key
    }
    contentChecksum = sha256(join("", [for filename in local.retention_bootstrap_files : filesha256("${path.module}/charts/retention-bootstrap/${filename}")]))
  })]

  depends_on = [helm_release.this]
}
