variable "configs" {
  type = object({
    repository       = optional(string, "https://istio-release.storage.googleapis.com/charts") # The istio helm charts repository
    namespace        = optional(string, "istio-system")                                        # the namespace where istio and related components will be installed
    create_namespace = optional(bool, true)                                                    # whether to create namespace or not
    atomic           = optional(bool, false)                                                   # whether auto rollback if helm install fails
    wait             = optional(bool, true)                                                    # whether wait to get the workload run successfully
    base = optional(object({                                                                   # istio-base configuration
      enabled       = optional(bool, true)                                                     # weather install istio-base helm chart
      name          = optional(string, "istio-base")                                           # the name of istio-base helm release
      chart_version = optional(string, "1.28.3")                                               # the version of istio-base chart
      values        = optional(any, {})                                                        # helm chart common default configs
      extra_values  = optional(any, {})                                                        # helm chart extra configs to pass and extend/use all available options
    }), {})
    istiod = optional(object({                   # istiod configuration
      enabled       = optional(bool, true)       # weather install istiod helm chart
      name          = optional(string, "istiod") # the name of istiod helm release
      chart_version = optional(string, "1.28.3") # the version of istio-base chart
      configs       = optional(any, {})          # helm chart common default configs
      extra_configs = optional(any, {})          # helm chart extra configs to pass and extend/use all available options
    }), {})
    gateway = optional(object({              # Gateway configuration (CRDs, Ingress Gateway, and Gateway API resources)
      crds = optional(object({               # k8s Gateway API CRDs configuration
        enabled = optional(bool, true)       # whether install Gateway API CRDs, in case if they are not enabled already
        version = optional(string, "v1.4.1") # the Gateway API CRDs version (e.g., v1.4.1, v1.1.0)
      }), {})
      ingress_gateway = optional(object({ # istio-gateway (ingress gateway) configuration
        # NOTE: The istio-gateway helm chart is NOT required when using Kubernetes native Gateway API resources.
        # It is only needed when using Istio's custom Gateway API implementation/CRDs (e.g., VirtualService, Gateway CRDs).
        # When using Kubernetes native Gateway API (gateway.networking.k8s.io), the gateway is managed through
        # Kubernetes Gateway resources and the istio-gateway helm chart can be disabled (enabled = false).
        # Additionally, the istio-gateway helm chart is also used for Istio ingress creation and management.
        # When enabled, it provides the ingress gateway service that can be used with Kubernetes Ingress resources
        # (via IngressClass) to route traffic into the Istio service mesh.
        enabled       = optional(bool, false)                    # whether install istio-gateway helm chart (default: false, not needed for native Gateway API)
        name          = optional(string, "istio-ingressgateway") # the name of istio-gateway helm release
        chart_version = optional(string, "1.28.3")               # the version of istio-gateway chart
        configs       = optional(any, {})                        # helm chart common default configs
        extra_configs = optional(any, {})                        # helm chart extra configs to pass and extend/use all available options
        ingress_class = optional(object({                        # Kubernetes IngressClass configuration for Istio ingress
          create = optional(bool, true)                          # whether to create IngressClass resource (default: true)
          name   = optional(string, "istio")                     # the name of the IngressClass (default: "istio")
        }), {})                                                  # This IngressClass allows Kubernetes Ingress resources to use Istio's ingress gateway
      }), {})
      # Wrapper for all gateway-api helm chart objects (Gateways, HTTPRoutes, GRPCRoutes, etc.).
      # Resources will be created in configs.namespace. If gateways list is empty, Gateway API resources release will not be created.
      api_resources = optional(object({
        enabled          = optional(bool, true)                               # whether to create the gateway-api resources helm release
        chart            = optional(string, "gateway-api")                    # the gateway-api chart name
        chart_version    = optional(string, "0.1.1")                          # the version of gateway-api chart
        chart_repository = optional(string, "https://dasmeta.github.io/helm") # the repository of gateway-api chart
        gateways         = optional(any, [])                                  # list (or single object) of Gateway resources to create (gateway.networking.k8s.io)
        # Example:
        # gateways = [
        #   {
        #     name = "main"
        #     gatewayClassName = "istio"
        #     listeners = [
        #       { name = "http", hostname = "example.com", port = 80, protocol = "HTTP" }
        #     ]
        #   }
        # ]
        httpRoutes = optional(any, []) # list (or single object) of HTTPRoute resources
        # Example:
        # httpRoutes = [
        #   {
        #     name = "http-to-https-redirect"
        #     parentRefs = [{ name = "main", sectionName = "http-80" }]
        #     hostnames = ["*.example.com"]
        #     rules = [{ redirect = { scheme = "https", statusCode = 301 } }]
        #   }
        # ]
        grpcRoutes = optional(any, []) # list (or single object) of GRPCRoute resources
        # Example:
        # grpcRoutes = [
        #   {
        #     name = "grpc-service"
        #     parentRefs = [{ name = "main" }]
        #     hostnames = ["grpc.example.com"]
        #     rules = [{
        #       matches = [{ method = { type = "Exact", service = "my.Service", method = "Get" } }]
        #       backendRefs = [{ name = "my-service", port = 50051 }]
        #     }]
        #   }
        # ]
        tcpRoutes = optional(any, []) # list (or single object) of TCPRoute resources (experimental CRDs)
        tlsRoutes = optional(any, []) # list (or single object) of TLSRoute resources (experimental CRDs)
        udpRoutes = optional(any, []) # list (or single object) of UDPRoute resources (experimental CRDs)
        istio     = optional(any, {}) # Istio-specific resources (AuthorizationPolicy, VirtualService, etc.)
        # Example:
        # istio = {
        #   defaultTargetRefs = [{ name = "main", namespace = "istio-system" }]
        #   authorizationPolicies = [{
        #     name = "block-admin"
        #     targetRefs = [{ name = "main" }]
        #     rules = [{ to = [{ operation = { paths = ["/admin*"] } }] }]
        #   }]
        #   virtualServices = [{
        #     name = "my-vs", hosts = ["example.com"], gateways = ["istio-system/main"]
        #     http = [{ match = [{ uri = { prefix = "/api" } }], route = [{ destination = { host = "my-service", port = { number = 80 } } }] }]
        #   }]
        # }
      }), {})
    }), {})
  })
  description = "The Istio setup configs"
  default     = {}
}
