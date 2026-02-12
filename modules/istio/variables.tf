variable "configs" {
  type = object({
    repository       = optional(string, "https://istio-release.storage.googleapis.com/charts") # The istio helm charts repository
    namespace        = optional(string, "istio-system")                                        # the namespace where istio and related components will be installed
    create_namespace = optional(bool, true)                                                    # whether to create namespace or not
    atomic           = optional(bool, false)                                                   # whether auto rollback if helm install fails
    wait             = optional(bool, true)                                                    # whether wait to get the workload run successfully
    gateway_api_crds = optional(object({                                                       # k8s Gateway API crds
      enabled       = optional(bool, true)                                                     # whether install crds, in case if they are not enabled already
      name          = optional(string, "gateway-api-crds")                                     # the name of gateway-api-crds helm release
      chart         = optional(string, "gateway-api-crds")                                     # the chart name for gateway-api-crds
      chart_version = optional(string, "1.28.3")                                               # the chart version for gateway-api-crds
    }))
    base = optional(object({                         # istio-base configuration
      enabled       = optional(bool, true)           # weather install istio-base helm chart
      name          = optional(string, "istio-base") # the name of istio-base helm release
      chart_version = optional(string, "1.28.3")     # the version of istio-base chart
      values        = optional(any, {})              # helm chart common default configs
      extra_values  = optional(any, {})              # helm chart extra configs to pass and extend/use all available options
    }))
    istiod = optional(object({                   # istiod configuration
      enabled       = optional(bool, true)       # weather install istiod helm chart
      name          = optional(string, "istiod") # the name of istiod helm release
      chart_version = optional(string, "1.28.3") # the version of istio-base chart
      configs       = optional(any, {})          # helm chart common default configs
      extra_configs = optional(any, {})          # helm chart extra configs to pass and extend/use all available options
    }))
    gateway = optional(object({                         # istio-gateway configuration
      enabled       = optional(bool, true)              # weather install istio-gateway helm chart
      name          = optional(string, "istio-gateway") # the name of istio-gateway helm release
      chart_version = optional(string, "1.28.3")        # the version of istio-base chart
      configs       = optional(any, {})                 # helm chart common default configs
      extra_configs = optional(any, {})                 # helm chart extra configs to pass and extend/use all available options
    }))
  })
  description = "The Istio setup configs"
  default     = {}
}
