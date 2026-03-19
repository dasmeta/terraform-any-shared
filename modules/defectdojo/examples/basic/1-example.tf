module "defectdojo" {
  source = "../.."

  custom_configs = {
    host = "defectdojo.example.com"
    django = {
      ingress = {
        enabled          = true
        ingressClassName = "nginx"
        activateTLS      = true
        annotations = {
          "cert-manager.io/cluster-issuer" = "letsencrypt"
        }
      }
    }
  }
}
