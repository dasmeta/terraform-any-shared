module "renovate" {
  source = "../.."

  renovate_configs = {
    token        = "your-gitlab-token" # GitLab PAT with repo access
    github_token = "your-github-token" # GitHub PAT (e.g. for release notes)
    schedule     = "*/2 * * * *"
  }

  # Options not in renovate_configs: only run on repos that already have renovate.json
  renovate_extra_configs = {
    onboarding    = false
    requireConfig = "required"
  }

  helm_extra_configs = {}
}
