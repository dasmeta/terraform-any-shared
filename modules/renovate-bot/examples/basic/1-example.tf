module "renovate" {
  source = "../.."

  platform = "gitlab"

  token        = "your-gitlab-token" # GitLab PAT with repo access
  github_token = "your-github-token" # GitHub PAT (e.g. for release notes)

  schedule = "*/15 * * * *"

  autodiscover = true # discover all repos the token can access

  host_rules    = []
  package_rules = []

  # Only run on repos that already have renovate.json; don't create onboarding PRs everywhere
  extra_config = jsonencode({
    onboarding    = false
    requireConfig = "required"
  })

  custom_configs = {}
}
