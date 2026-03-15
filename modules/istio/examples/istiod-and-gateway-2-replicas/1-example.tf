# Example: Istiod and Gateway API with 2 replicas
#
# This configuration demonstrates:
# - Istiod with autoscaleMin = 2 (minimum 2 replicas for the control plane)
# - Gateway API gateway with deployment.spec.replicas = 2 (2 gateway proxy replicas)
# - Same pattern as terraform-aws-eks/examples/eks-with-istio-gateway-api

module "this" {
  source = "../.."

  configs = {
    gateway = {
      ingress_gateway = {
        enabled = false
      }
      api_resources = {
        gateways = [
          {
            name             = "main"
            gatewayClassName = "istio"
            listeners = [
              {
                name     = "http-80"
                hostname = "example.localhost"
                port     = 80
                protocol = "HTTP"
                allowedRoutes = {
                  namespaces = {
                    from = "All"
                  }
                }
              }
            ]
            # 2 replicas for the gateway deployment (gateway proxy pods)
            infrastructure = {
              parameters = {
                deployment = {
                  spec = {
                    replicas = 2
                    # can be used to customize the gateway proxy pods template
                    # template = {
                    #   spec = {
                    #     nodeSelector = {
                    #       "kubernetes.io/os" = "linux"
                    #     }
                    #     containers = [
                    #       {
                    #         name = "istio-proxy"
                    #         resources = {
                    #           requests = {
                    #             cpu    = "12m"
                    #             memory = "12Mi"
                    #           }
                    #         }
                    #       }
                    #     ]
                    #   }
                    # }
                  }
                }
              }
            }
          }
        ]
      }
    }
    # Istiod with minimum 2 replicas (control plane HA)
    istiod = {
      configs = {
        global = {
          proxy = {
            autoInject = "disabled"
          }
        }
        autoscaleMin = 2
      }
    }
  }
}
