variable "notification_channels" {
  type = object({
    slack_webhook_url = optional(string, "")
    teams_webhook_url = optional(string, "")
    opsgenie_api_key  = optional(string, "")
  })
  sensitive   = true
  nullable    = false
  description = "Direct credentials for at least one destination. Set only slack_webhook_url for Slack-only, optionally teams_webhook_url and/or opsgenie_api_key. One Opsgenie integration authenticates findings and P5 summaries; paging depends on its rules. Terraform and Helm state store the credentials."
}
