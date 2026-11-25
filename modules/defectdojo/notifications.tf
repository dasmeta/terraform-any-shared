locals {
  notifications_channels_configured = trimspace(var.notifications.channels_secret.name) != "" || anytrue([
    for value in values(var.notifications.channels) : trimspace(value) != ""
  ])
  notifications_requested = var.notifications.enabled != null ? var.notifications.enabled : local.notifications_channels_configured
  # Resource presence is public metadata; credential values stay sensitive.
  # try supports both sensitive channel inputs and ordinary literal values.
  notifications_enabled            = try(nonsensitive(local.notifications_requested), local.notifications_requested)
  notifications_release_name       = "${var.name}-notifications"
  notifications_mysql_release_name = "${var.name}-notifications-mysql"
  notifications_mysql_managed      = local.notifications_enabled && var.notifications.mysql.create
  notifications_api_token_source   = var.notifications.api_token_secret.name != "" ? "explicit" : var.retention.enabled ? "retention" : "bootstrap"
  # Source selection and iteration must not depend on sensitive credential values.
  notifications_create_channels_secret = local.notifications_enabled && var.notifications.channels_secret.name == ""
  notifications_channels_secret = var.notifications.channels_secret.name == "" ? {
    name         = "${var.name}-notifications-channels"
    slack_key    = "slack-url"
    teams_key    = "teams-url"
    opsgenie_key = "opsgenie-key"
  } : var.notifications.channels_secret
  # Compare HTTP origins without treating a scheme's explicit default port as a different deployment.
  notifications_api_origin           = replace(replace(lower(trimsuffix(var.notifications.api_url, "/")), "/^(http://[^:]+):0*80$/", "$1"), "/^(https://[^:]+):0*443$/", "$1")
  notifications_retention_api_origin = replace(replace(lower(trimsuffix(var.retention.api_url, "/")), "/^(http://[^:]+):0*80$/", "$1"), "/^(https://[^:]+):0*443$/", "$1")
  notifications_api_token_secret = {
    name = var.notifications.api_token_secret.name != "" ? var.notifications.api_token_secret.name : var.retention.enabled ? local.retention_token_secret_name : "${var.name}-notifications-api"
    key  = var.notifications.api_token_secret.name == "" && var.retention.enabled ? var.retention.api_token_secret.key : var.notifications.api_token_secret.key
  }
  notifications_mysql_credentials_secret = var.notifications.mysql.create ? {
    name         = "${local.notifications_mysql_release_name}-credentials"
    username_key = "username"
    password_key = "password"
  } : var.notifications.mysql.credentials_secret
  notifications_mysql_ca_secret = var.notifications.mysql.create ? {
    name = "${local.notifications_mysql_release_name}-credentials"
    key  = "ca.crt"
  } : var.notifications.mysql.ca_secret
  notifications_mysql_host = var.notifications.mysql.create ? "${local.notifications_mysql_release_name}.${var.namespace}.svc" : var.notifications.mysql.host
  notifications_source_files = {
    for filename in sort(fileset("${path.module}/notifier/notifier", "*.py")) : filename => file("${path.module}/notifier/notifier/${filename}")
  }
  notifications_wheel_files = {
    for filename in sort(fileset("${path.module}/notifier/vendor", "*.whl")) : filename => filebase64("${path.module}/notifier/vendor/${filename}")
  }
  notifications_policy = merge({
    namespace       = sha256(jsonencode([var.namespace, var.name, local.notifications_api_origin]))
    api_url         = trimsuffix(var.notifications.api_url, "/")
    engagement_ids  = [for id in sort([for id in var.notifications.engagement_ids : tostring(id)]) : tonumber(id)]
    all_engagements = var.notifications.all_engagements
    time_zone       = var.notifications.time_zone
    mysql = merge({
      host     = local.notifications_mysql_host
      port     = var.notifications.mysql.port
      database = var.notifications.mysql.database
      tls      = var.notifications.mysql.tls
      }, local.notifications_mysql_ca_secret.name == "" ? {} : {
      ca_file = "/var/run/secrets/mysql-ca/ca.crt"
    })
    opsgenie_region = var.notifications.opsgenie_region
    priority        = var.notifications.priority
    }, var.notifications.opsgenie_title_prefix == "" ? {} : {
    opsgenie_title_prefix = var.notifications.opsgenie_title_prefix
  })
  notifications_chart_files = sort([
    for filename in fileset("${path.module}/charts/notifications", "**") : filename
    if length(regexall("(^|/)__pycache__(/|$)|\\.pyc$", filename)) == 0
  ])
  notifications_mysql_chart_files = sort([
    for filename in fileset("${path.module}/charts/notifications-mysql", "**") : filename
    if length(regexall("(^|/)__pycache__(/|$)|\\.pyc$", filename)) == 0
  ])
  notifications_mysql_bootstrap_chart_files = sort([
    for filename in fileset("${path.module}/charts/notifications-mysql-bootstrap", "**") : filename
    if length(regexall("(^|/)__pycache__(/|$)|\\.pyc$", filename)) == 0
  ])
}

resource "helm_release" "notifications_api_bootstrap" {
  count = local.notifications_enabled && local.notifications_api_token_source == "bootstrap" ? 1 : 0

  name      = "${var.name}-notify-token"
  namespace = var.namespace
  chart     = "${path.module}/charts/retention-bootstrap"
  version   = "0.1.0"
  wait      = true
  atomic    = var.atomic
  timeout   = 900

  values = [jsonencode({
    image              = var.notifications.image
    apiUrl             = var.notifications.api_url
    sourceFullname     = local.retention_application_fullname
    applicationRelease = var.name
    keepSecret         = false
    targetSecret       = local.notifications_api_token_secret
    contentChecksum    = sha256(join("", [for filename in local.retention_bootstrap_files : filesha256("${path.module}/charts/retention-bootstrap/${filename}")]))
  })]

  depends_on = [helm_release.this]
}

resource "helm_release" "notifications_mysql_bootstrap" {
  count = local.notifications_mysql_managed ? 1 : 0

  name      = "${var.name}-notifications-db-init"
  namespace = var.namespace
  chart     = "${path.module}/charts/notifications-mysql-bootstrap"
  version   = "0.1.0"
  # Automatic uninstall after a failed install must never invoke state purge.
  atomic  = false
  wait    = true
  timeout = 900

  values = [jsonencode({
    enabled         = true
    retainState     = var.notifications.retain_state
    image           = var.notifications.image
    mysqlImage      = var.notifications.mysql.image
    targetSecret    = { name = local.notifications_mysql_credentials_secret.name }
    serviceName     = local.notifications_mysql_release_name
    namespace       = var.namespace
    pvcName         = "data-${local.notifications_mysql_release_name}-0"
    contentChecksum = sha256(join("", [for filename in local.notifications_mysql_bootstrap_chart_files : filesha256("${path.module}/charts/notifications-mysql-bootstrap/${filename}")]))
  })]

  depends_on = [helm_release.this]
}

resource "helm_release" "notifications_mysql" {
  count = local.notifications_mysql_managed ? 1 : 0

  name      = local.notifications_mysql_release_name
  namespace = var.namespace
  chart     = "${path.module}/charts/notifications-mysql"
  version   = "0.1.0"
  atomic    = var.atomic
  wait      = true
  timeout   = 900

  values = [jsonencode({
    enabled           = true
    image             = var.notifications.mysql.image
    credentialsSecret = local.notifications_mysql_credentials_secret.name
    database          = var.notifications.mysql.database
    username          = "notifier"
    persistence = {
      size         = var.notifications.mysql.storage_size
      storageClass = var.notifications.mysql.storage_class
    }
    workerRelease   = local.notifications_release_name
    contentChecksum = sha256(join("", [for filename in local.notifications_mysql_chart_files : filesha256("${path.module}/charts/notifications-mysql/${filename}")]))
  })]

  depends_on = [helm_release.notifications_mysql_bootstrap]
}

resource "helm_release" "notifications" {
  count = local.notifications_enabled ? 1 : 0

  name      = local.notifications_release_name
  namespace = var.namespace
  chart     = "${path.module}/charts/notifications"
  version   = "0.1.0"
  atomic    = var.atomic
  wait      = var.wait
  timeout   = 3900

  values = [jsonencode({
    enabled              = true
    createChannelsSecret = local.notifications_create_channels_secret
    managedMysql         = var.notifications.mysql.create
    sourceFiles          = local.notifications_source_files
    wheelFiles           = local.notifications_wheel_files
    image                = var.notifications.image
    pollSchedule         = var.notifications.poll_schedule
    digestSchedule       = var.notifications.digest_schedule
    timeZone             = var.notifications.time_zone
    apiTokenSecret       = local.notifications_api_token_secret
    mysqlCredentialsSecret = {
      name        = local.notifications_mysql_credentials_secret.name
      usernameKey = local.notifications_mysql_credentials_secret.username_key
      passwordKey = local.notifications_mysql_credentials_secret.password_key
    }
    mysqlCaSecret = {
      name = local.notifications_mysql_ca_secret.name
      key  = local.notifications_mysql_ca_secret.key
    }
    channelsSecret = {
      name        = local.notifications_channels_secret.name
      slackKey    = local.notifications_channels_secret.slack_key
      teamsKey    = local.notifications_channels_secret.teams_key
      opsgenieKey = local.notifications_channels_secret.opsgenie_key
    }
    policy = local.notifications_policy
    contentChecksum = sha256(jsonencode({
      chart  = [for filename in local.notifications_chart_files : filesha256("${path.module}/charts/notifications/${filename}")]
      source = local.notifications_source_files
      wheels = local.notifications_wheel_files
    }))
  })]

  dynamic "set_sensitive" {
    # Keep all three settings even for Slack-only input: sensitive values cannot select iteration keys.
    for_each = local.notifications_create_channels_secret ? {
      slack-url    = "slack_webhook_url"
      teams-url    = "teams_webhook_url"
      opsgenie-key = "opsgenie_api_key"
    } : {}
    content {
      name = "channelsData.${set_sensitive.key}"
      # Base64 preserves commas, braces, backslashes and other Helm strvals syntax.
      value = base64encode(var.notifications.channels[set_sensitive.value])
      type  = "string"
    }
  }

  depends_on = [helm_release.this, helm_release.retention_bootstrap, helm_release.notifications_api_bootstrap, helm_release.notifications_mysql_bootstrap, helm_release.notifications_mysql]

  lifecycle {
    precondition {
      condition     = local.notifications_api_token_source != "retention" || local.notifications_api_origin == local.notifications_retention_api_origin
      error_message = "Automatic retention-token reuse requires matching notification and retention API origins. For intentional different origins or aliases, explicitly set notifications.api_token_secret.name/key to the appropriate existing Secret."
    }
    precondition {
      condition     = length(local.notifications_source_files) > 0 && length(local.notifications_wheel_files) == 2 && length(base64encode(jsonencode(local.notifications_source_files))) <= 1200000 && length(jsonencode(local.notifications_wheel_files)) <= 900000
      error_message = "The bundled notifier source and two dependency wheels are required, with each ConfigMap bundle below 900KB including encoding overhead."
    }
    precondition {
      condition     = length(var.name) <= 31 && can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.name))
      error_message = "When notifications are enabled, name must be a lowercase DNS label of at most 31 characters, leaving room for the notification CronJob suffix."
    }
  }
}
