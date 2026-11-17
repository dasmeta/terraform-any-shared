module "defectdojo" {
  source = "../.."

  name          = "example-defectdojo"
  namespace     = "example-security"
  chart_version = "1.9.64"

  notifications = {
    retain_state    = false
    api_url         = "https://defectdojo.example.com"
    engagement_ids  = [7, 9]
    poll_schedule   = "0 * * * *"
    digest_schedule = "30 13 * * *"
    time_zone       = "UTC"
    # Managed MySQL is enabled by default with an 8Gi persistent volume.
    # mysql = { storage_size = "16Gi", storage_class = "example-storage" }
    # Supply only slack_webhook_url for Slack-only delivery; other destinations are optional.
    channels = var.notification_channels
    # Direct credentials are stored in Terraform and Helm state.
    # Alternatively, replace channels above with an existing Secret containing only selected keys:
    # channels_secret = { name = "example-notifier-channels" }
    opsgenie_region = "us"
    priority        = "P2"
  }
}
