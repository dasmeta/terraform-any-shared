resource "helm_release" "mongodb_bi_connector" {
  name = var.name

  chart      = "mongodb-bi-connector"
  repository = "https://dasmeta.github.io/helm"
  version    = "1.0.1"
  namespace  = var.namespace

  set {
    name  = "mongosqldConfig.mongodb.net.auth.username"
    value = var.mongodb_username
  }

  set {
    name  = "mongosqldConfig.mongodb.net.auth.password"
    value = var.mongodb_password
  }

  set {
    name  = "mongosqldConfig.mongodb.net.uri"
    value = var.mongodb_uri
  }
}
