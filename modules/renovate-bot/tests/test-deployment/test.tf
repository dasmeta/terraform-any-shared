module "renovate-bot" {
  source = "../../"

  platform = "gitlab"
  endpoint = "https://gitlab.example.com/api/v4"

  token        = "**********"
  github_token = "**********"
  schedule     = "0 1 * * *"
  autodiscover = true

  cluster_name = "eks"

  host_rules = [
    {
      matchHost = "https://some.private.registry",
      token     = "**********",
      hostType  = "npm"
    }
  ]
}
