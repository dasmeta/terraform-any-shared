module "this" {
  source = "../"

  name      = "horizon"
  namespace = "horizon"

  image = {
    repository = "dasmeta/horizon-monitor"
    tag        = "0.0.2"
  }

  container_port = 8000

  config = {
    APP_NAME = "horizon"
    APP_ENV  = "dev"
    APP_URL  = "https://horizon.example.com"
  }

  ingress = {
    enabled = true
    class   = "nginx"
    hosts = [
      {
        host = "horizon.example.com"
        paths = [
          {
            path     = "/"
            pathType = "Prefix"
          }
        ]
      }
    ]
    annotations = {
      "cert-manager.io/cluster-issuer"                 = "letsencrypt-prod"
      "nginx.ingress.kubernetes.io/force-ssl-redirect" = "true"
    }
    tls = [
      {
        hosts      = ["horizon.example.com"]
        secretName = "horizon-example-com-certificate-cms"
      }
    ]
  }

  resources = {
    requests = {
      cpu    = "100m"
      memory = "128Mi"
    }
    limits = {
      cpu    = "500m"
      memory = "512Mi"
    }
  }
}
