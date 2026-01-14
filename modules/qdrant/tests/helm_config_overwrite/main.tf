locals {
  cluster_name = "dev"
  region       = "eu-central-1"
}

module "qdrant" {
  source = "./../../"

  namespace = "qdrant"
  config = {
    replicaCount = 2

    persistence = {
      size = "5Gi"
    }

    ingress = {
      enabled          = false
      ingressClassName = "nginx"
      hosts = [
        {
          host = "qdrant.example.com"
          paths = [
            { path = "/", pathType = "Prefix", servicePort = 6333 }
          ]
        }
      ]
    }
  }
}
