module "this" {
  source = "../../"

  helm_values = {
    "image" : {
      "repository" : "repository: xxxxx.dkr.ecr.us-east-1.amazonaws.com/api",
      "tag" : "latest"
    },
    "config" : {
      "NODE_ENV" : "dev"
      "PORT" : "8080"
      "MONGODB_URI" : "mongodb+srv://username:password@db?retryWrites=true&w=majority"
    },
    "podAnnotations" : {
      "linkerd.io/inject" : "enabled"
    },
    "replicaCount" : 2,
  }
  name         = "api01"
  namespace    = "test"
  cluster_name = "eks-dev"

  alarms = {
    sns_topic = "Default"
    custom_values = {
      cpu = {
        period    = 300,
        statistic = "avg",
        threshold = 80
        equation  = "gte"
      },
      memory = {
        period    = 300,
        statistic = "avg",
        threshold = 80
        equation  = "gte"
      },
      restarts = {
        period    = 300,
        statistic = "max",
        threshold = 3
        equation  = "gte"
      },
      replicas = {
        period    = 300,
        statistic = "avg",
        threshold = 0
        equation  = "lte"
      },
    }
  }
}
