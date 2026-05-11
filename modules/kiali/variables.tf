variable "configs" {
  type = object({
    enabled = optional(bool, true) # whether to deploy Kiali observability components
    operator = optional(object({
      enabled          = optional(bool, true)                              # whether to install the Kiali operator Helm chart
      name             = optional(string, "kiali-operator")                # the Kiali operator Helm release name
      namespace        = optional(string, "kiali-operator")                # the namespace where the Kiali operator will be installed
      chart            = optional(string, "kiali-operator")                # the Kiali operator chart name or direct .tgz URL
      chart_repository = optional(string, "https://kiali.org/helm-charts") # Kiali operator Helm chart repository
      chart_version    = optional(string, "2.25.0")                        # optional Kiali operator chart version
      create_namespace = optional(bool, true)                              # whether Helm should create the operator namespace
      atomic           = optional(bool, false)                             # whether Helm should roll back on failure
      wait             = optional(bool, true)                              # whether Helm should wait for resources to become ready
      image = optional(object({
        # Kiali operator chart exposes image.repo/tag/digest for operator image itself.
        # When Kiali server custom image is configured through Kiali CR deployment fields
        # (`spec.deployment.image_name` / `image_version`), this module auto-enables
        # chart value `allowAdHocKialiImage=true` internally; no explicit field is required.
        repo   = optional(string) # operator image repository override
        tag    = optional(string) # operator image tag override
        digest = optional(string) # operator image digest override
      }), {})
      values       = optional(any, {}) # Kiali operator chart values
      extra_values = optional(any, {}) # extra Kiali operator chart values
    }), {})
    cr = optional(object({
      enabled        = optional(bool, true)             # whether to create a Kiali custom resource
      name           = optional(string, "kiali")        # the Kiali custom resource name
      namespace      = optional(string, "istio-system") # the Kiali custom resource namespace
      labels         = optional(map(string), {})        # labels applied to the Kiali custom resource
      annotations    = optional(map(string), {})        # annotations applied to the Kiali custom resource
      auth_strategy  = optional(string, "anonymous")    # Kiali auth strategy
      view_only_mode = optional(bool, false)            # whether Kiali should run in view-only mode
      deployment     = optional(any, {})                # Kiali spec.deployment overrides
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
  })
  description = "Kiali operator and Kiali custom resource configuration"
  default     = {}
}
