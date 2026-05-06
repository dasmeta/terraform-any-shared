module "this" {
  source = "../.."

  configs = {
    cr = {
      external_services = {
        prometheus = {
          url = "http://prometheus-kube-prometheus-prometheus.monitoring:9090/"
        }
      }
    }
  }
}
