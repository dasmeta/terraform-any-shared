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
  name      = "api01"
  namespace = "test"
}
