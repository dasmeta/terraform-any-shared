variable "configs" {
  type = object({
    chart = optional(object({                                                                    # Global Helm chart defaults for Istio releases (repository/version/namespace and release behavior)
      repository       = optional(string, "https://istio-release.storage.googleapis.com/charts") # global istio helm charts repository
      version          = optional(string, "1.29.2")                                              # fallback version for istio base/gateway/istiod charts
      namespace        = optional(string, "istio-system")                                        # the namespace where istio and related components will be installed
      create_namespace = optional(bool, true)                                                    # whether to create namespace or not
      atomic           = optional(bool, false)                                                   # whether auto rollback if helm install fails
      wait             = optional(bool, true)                                                    # whether wait to get the workload run successfully
      timeout          = optional(number, 300)                                                   # wait timeout in seconds (default 5 minutes)
    }), {})
    image = optional(object({      # global image settings used by Istio components
      registry  = optional(string) # image registry host (for example: docker.io, ghcr.io), default is empty which means it points to "docker.io"
      namespace = optional(string) # image namespace/org path used as hub (for example: istio), default is empty which means it points to "istio
      tag       = optional(string) # image tag shared across Istio components, default is empty which means it points to version from helm chart which usually for istio is the same as the helm chart version
      repository = optional(object({
        istiod = optional(string) # istiod controller image name (helm value `image`), default from chart is usually `pilot` when not set
        proxy  = optional(string) # istio data-plane proxy image name (helm value `global.proxy.image`), default from chart is usually `proxyv2` when not set
      }), {})
    }), {})
    base = optional(object({                        # istio-base configuration
      enabled      = optional(bool, true)           # weather install istio-base helm chart
      name         = optional(string, "istio-base") # the name of istio-base helm release
      chart        = optional(string, "base")       # optional per-component chart name or direct .tgz URL override
      repository   = optional(string)               # optional per-component chart repository override
      version      = optional(string)               # optional per-component chart version override
      values       = optional(any, {})              # helm chart common default configs
      extra_values = optional(any, {})              # helm chart extra configs to pass and extend/use all available options
    }), {})
    istiod = optional(object({                   # istiod configuration
      enabled       = optional(bool, true)       # weather install istiod helm chart
      name          = optional(string, "istiod") # the name of istiod helm release
      chart         = optional(string, "istiod") # optional per-component chart name or direct .tgz URL override
      repository    = optional(string)           # optional per-component chart repository override
      version       = optional(string)           # optional per-component chart version override
      configs       = optional(any, {})          # helm chart common default configs
      extra_configs = optional(any, {})          # helm chart extra configs to pass and extend/use all available options
    }), {})
    gateway = optional(object({        # Gateway configuration (CRDs, Ingress Gateway, and Gateway API resources)
      crds = optional(object({         # k8s Gateway API CRDs configuration
        enabled = optional(bool, true) # whether install Gateway API CRDs, in case if they are not enabled already
      }), {})
      ingress_gateways = optional(list(object({ # istio-gateway (ingress gateway) configurations
        # NOTE: The istio-gateway helm chart is NOT required when using Kubernetes native Gateway API resources.
        # It is only needed when using Istio's custom Gateway API implementation/CRDs (e.g., VirtualService, Gateway CRDs).
        # When using Kubernetes native Gateway API (gateway.networking.k8s.io), the gateway is managed through
        # Kubernetes Gateway resources and the istio-gateway helm chart can be omitted.
        name          = optional(string, "istio-ingressgateway") # helm release name; when defining multiple ingress gateways this must be unique per item
        chart         = optional(string, "gateway")              # optional per-component chart name or direct .tgz URL override
        repository    = optional(string)                         # optional per-component chart repository override
        version       = optional(string)                         # optional per-component chart version override
        configs       = optional(any, {})                        # helm chart common default configs
        extra_configs = optional(any, {})                        # helm chart extra configs to pass and extend/use all available options
        ingress_class = optional(object({                        # Kubernetes IngressClass configuration for Istio ingress
          create = optional(bool, true)                          # whether to create IngressClass resource (default: true)
          name   = optional(string, "istio")                     # must be unique if multiple ingress gateways create ingress classes
        }), {})
      })), [])
      # Wrapper for all gateway-api helm chart objects (Gateways, HTTPRoutes, GRPCRoutes, etc.).
      # Resources will be created in configs.chart.namespace. If gateways list is empty, Gateway API resources release will not be created.
      api_resources = optional(object({
        name             = optional(string, "gateway-api-resources")          # name of the gateway-api resources helm release
        enabled          = optional(bool, true)                               # whether to create the gateway-api resources helm release
        chart            = optional(string, "gateway-api")                    # the gateway-api chart name or direct .tgz URL
        chart_version    = optional(string, "0.1.7")                          # the version of gateway-api chart
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
    kiali = optional(object({
      enabled = optional(bool, false) # whether to deploy Kiali observability components
      operator = optional(object({
        enabled          = optional(bool, true)                              # whether to install the Kiali operator Helm chart
        name             = optional(string, "kiali-operator")                # the Kiali operator Helm release name
        namespace        = optional(string, null)                            # the namespace where the Kiali operator will be installed; defaults to configs.chart.namespace
        chart            = optional(string, "kiali-operator")                # the Kiali operator chart name or direct .tgz URL
        chart_repository = optional(string, "https://kiali.org/helm-charts") # Kiali operator Helm chart repository
        chart_version    = optional(string, "2.25.0")                        # optional Kiali operator chart version
        create_namespace = optional(bool, true)                              # whether Helm should create the operator namespace
        atomic           = optional(bool, false)                             # whether Helm should roll back on failure
        wait             = optional(bool, true)                              # whether Helm should wait for resources to become ready
        image = optional(object({
          registry  = optional(string) # shared image registry host for Kiali operator/server (example: quay.io, ghcr.io)
          namespace = optional(string) # shared image namespace/org path for Kiali operator/server (example: kiali)
          tag       = optional(string) # shared image tag used for both Kiali operator and server images
          # `allowAdHocKialiImage` is auto-enabled internally when server image override is used.
          repository = optional(object({
            operator = optional(string) # operator image repository name/path (without registry/namespace)
            server   = optional(string) # server image repository name/path (without registry/namespace)
          }), {})
        }), {})
        values       = optional(any, {}) # Kiali operator chart values
        extra_values = optional(any, {}) # extra Kiali operator chart values
      }), {})
      cr = optional(object({
        enabled        = optional(bool, true)          # whether to create a Kiali custom resource
        name           = optional(string, "kiali")     # the Kiali custom resource name
        namespace      = optional(string, null)        # the Kiali custom resource namespace; defaults to configs.chart.namespace when called through Istio
        labels         = optional(map(string), {})     # labels applied to the Kiali custom resource
        annotations    = optional(map(string), {})     # annotations applied to the Kiali custom resource
        auth_strategy  = optional(string, "anonymous") # Kiali auth strategy
        view_only_mode = optional(bool, false)         # whether Kiali should run in view-only mode
        deployment     = optional(any, {})             # Kiali spec.deployment overrides
        external_services = optional(object({
          prometheus = optional(object({
            url              = optional(string)      # Prometheus internal service URL used by Kiali
            auth             = optional(any)         # Prometheus auth configuration
            custom_headers   = optional(map(string)) # custom headers sent to Prometheus
            health_check_url = optional(string)      # optional Prometheus health check URL
            is_core          = optional(bool)        # whether Prometheus is a core service
            query_scope      = optional(map(string)) # query scope labels such as mesh_id or cluster
            thanos_proxy     = optional(any)         # Thanos proxy configuration
            extra_configs    = optional(any, {})     # extra Prometheus settings merged into spec.external_services.prometheus
          }), {})
          grafana = optional(object({
            enabled          = optional(bool)      # whether Grafana integration is enabled
            internal_url     = optional(string)    # Grafana URL reachable inside the cluster
            external_url     = optional(string)    # Grafana URL opened by users from Kiali
            datasource_uid   = optional(string)    # Grafana datasource UID for Prometheus
            dashboards       = optional(list(any)) # Grafana dashboard definitions used by Kiali links
            auth             = optional(any)       # Grafana auth configuration
            health_check_url = optional(string)    # optional Grafana health check URL
            is_core          = optional(bool)      # whether Grafana is a core service
            extra_configs    = optional(any, {})   # extra Grafana settings merged into spec.external_services.grafana
          }), {})
        }), {})
        spec = optional(any, {}) # extra Kiali CR spec values; overrides generated common-case fields on key conflict
      }), {})
    }), {})
  })
  description = "The Istio setup configs"
  default     = {}

  validation {
    condition = (
      (try(var.configs.image.registry, null) == null || try(var.configs.image.registry, "") != "") &&
      (try(var.configs.image.namespace, null) == null || try(var.configs.image.namespace, "") != "") &&
      (try(var.configs.image.tag, null) == null || try(var.configs.image.tag, "") != "") &&
      (try(var.configs.image.repository.istiod, null) == null || try(var.configs.image.repository.istiod, "") != "") &&
      (try(var.configs.image.repository.proxy, null) == null || try(var.configs.image.repository.proxy, "") != "")
    )
    error_message = "Global image fields (registry/namespace/tag) are optional, but if set they must be non-empty strings."
  }
}
