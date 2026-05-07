module "this" {
  source = "../.."

  configs = {
    chart = {
      namespace = "istio-system"
    }

    kiali = {
      enabled = true
      operator = {
        chart_repository = "https://kiali.org/helm-charts"
        image = {
          registry  = "quay.io"
          namespace = "kiali"
          tag       = "latest"
          repository = {
            operator = "kiali-operator"
          }
        }
      }

      cr = {
        auth_strategy  = "anonymous"
        view_only_mode = true

        external_services = {
          prometheus = {
            url = "http://prometheus.monitoring:9090/"
          }

          grafana = {
            enabled        = true
            internal_url   = "http://grafana.monitoring:3000/"
            external_url   = "https://grafana.example.com/"
            datasource_uid = "prometheus"
            dashboards = [
              {
                name = "Istio Service Dashboard"
                variables = {
                  datasource = "var-datasource"
                  namespace  = "var-namespace"
                  service    = "var-service"
                }
              }
            ]
          }
        }
      }
    }
  }
}
