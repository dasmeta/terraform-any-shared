module "defectdojo" {
  source = "../.."

  name          = local.release_name
  namespace     = "example-security"
  chart_version = "1.9.64"

  retention = {
    enabled          = true
    days             = 30
    schedule         = "17 2 * * *"
    time_zone        = "Etc/UTC"
    api_url          = "https://defectdojo.example.com"
    engagement_names = var.engagement_names
    api_token_secret = {
      create = true
      name   = "example-defectdojo-retention"
      key    = "api-key"
    }
    protected_branches     = ["deploy-primary"]
    protected_environments = ["primary"]
    max_tests_per_run      = 10
  }
}
