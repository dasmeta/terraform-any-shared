module "loki" {
  source = "../../"

  loki_storage = {
    type              = "digitalocean"
    access_key        = "DAT"
    secret_access_key = "llLHrX8"
    bucketname        = "loki-chunks-for-grafana"
    endpoint          = "fra1.digitaloceanspaces.com"
    region            = "fra1"
  }
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}
