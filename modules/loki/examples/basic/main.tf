module "loki" {
  source = "../../"

  loki_storage = {
    type = "no-external-storage"
  }
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}
