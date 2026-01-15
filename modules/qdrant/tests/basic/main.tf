locals {
  cluster_name = "dev"
  region       = "eu-central-1"
}

module "qdrant" {
  source = "./../../"

  namespace = "qdrant"
}
