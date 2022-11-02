module "renovate-bot" {
  source = "../../"

  platform = "gitlab"
  endpoint = "https://gitlab.example.com/api/v4"

  token        = "**********"
  schedule     = "0 1 * * *"
  autodiscover = true

  cluster_name = "eks"
}
