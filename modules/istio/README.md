# istio

Terraform module to install and manage Istio core components plus Gateway API integration on Kubernetes.

This module can:

- install Gateway API CRDs,
- install Istio `base` and `istiod`,
- optionally install Istio `gateway` chart for ingress mode,
- create Gateway API resources (`Gateway`, `HTTPRoute`, and others) through the `gateway-api` Helm chart.
- optionally call the `kiali` submodule to install the Kiali operator and manage a `Kiali` custom resource with Prometheus and Grafana integration.
- configure chart repository/version and release behavior globally via `configs.chart`, with per-component repository/version overrides.
- use direct HTTP(S) `.tgz` chart archive URLs in component chart fields; when a chart is a direct URL, the module omits repository/version for that Helm release.
- configure global Istio image hub/tag via `configs.image.registry`, `configs.image.namespace`, and `configs.image.tag`.

It is intended for setups where Istio is used as the Gateway API implementation (`gatewayClassName: istio`), including both gateway-only and service-mesh-enabled scenarios.

## Usage

### Minimal Example

```hcl
module "this" {
  source  = "dasmeta/shared/any//modules/istio"
  # version = "x.y.z" # Check https://registry.terraform.io/modules/dasmeta/shared/any/latest/submodules/istio and set the version

  configs = {
    chart = {
      repository       = "https://istio-release.storage.googleapis.com/charts"
      version          = "1.30.3"
      namespace        = "istio-system"
      create_namespace = true
      atomic           = false
      wait             = true
      timeout          = 300
    }
    image = {
      registry  = "docker.io"
      namespace = "istio"
      tag       = "1.30.3"
    }

    istiod = {
    }

    gateway = {
      ingress_gateways = [
        {
          name    = "istio-ingressgateway"
          version = "1.30.3"
        }
      ]
      api_resources = {
        chart_version = "0.1.7"
        gateways = [
          {
            name             = "main"
            gatewayClassName = "istio"
            listeners = [
              {
                name     = "http-80"
                hostname = "example.com"
                port     = 80
                protocol = "HTTP"
              }
            ]
          }
        ]
      }
    }
  }
}
```

### Kiali Observability Example

```hcl
module "this" {
  source  = "dasmeta/shared/any//modules/istio"
  # version = "x.y.z" # Check https://registry.terraform.io/modules/dasmeta/shared/any/latest/submodules/istio and set the version

  configs = {
    chart = {
      namespace = "istio-system"
    }

    kiali = {
      enabled = true
      operator = {
        chart_repository = "https://kiali.org/helm-charts"
        chart_version    = "2.29.0"
        image = {
          registry  = "quay.io"
          namespace = "kiali"
          tag       = "v2.29.0"
          repository = {
            operator = "kiali-operator"
            server   = "kiali"
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
              },
              {
                name = "Istio Workload Dashboard"
                variables = {
                  datasource = "var-datasource"
                  namespace  = "var-namespace"
                  workload   = "var-workload"
                }
              }
            ]
          }
        }
      }
    }
  }
}
```

Kiali is disabled by default. When enabled, this module delegates to `modules/kiali`, which installs the `kiali-operator` Helm chart and creates a `kiali.io/v1alpha1` `Kiali` custom resource.

Kiali chart/image settings are configured inside `configs.kiali.operator` (`chart_repository`, `chart_version`, and `image` with shared `registry`/`namespace`/`tag` plus `repository.operator`/`repository.server`).

## Upgrade Notes

- Istio chart fallback default is upgraded to `1.30.3`.
- Gateway API resources chart default is upgraded to `0.1.7`.
- Use `configs.chart` for global chart defaults and release behavior; use component `*.repository/version` to override per chart.
- Use direct HTTP(S) `.tgz` chart URLs in component `chart` fields when consuming chart archives directly; repository/version are ignored for those direct URL releases.
- Use `configs.image.registry`, `configs.image.namespace`, and `configs.image.tag` to set a shared image hub/tag for Istio control-plane and gateway chart workloads.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.0 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | ~> 1.14 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | ~> 2.0 |
| <a name="provider_kubectl"></a> [kubectl](#provider\_kubectl) | ~> 1.14 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_gateway_api_crds"></a> [gateway\_api\_crds](#module\_gateway\_api\_crds) | ../gateway-api-crds | n/a |
| <a name="module_kiali"></a> [kiali](#module\_kiali) | ../kiali | n/a |

## Resources

| Name | Type |
|------|------|
| [helm_release.gateway](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.gateway_api_resources](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.istio_base](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.istiod](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubectl_manifest.istio_ingress_class](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_gateway_api_crds_manifests"></a> [gateway\_api\_crds\_manifests](#output\_gateway\_api\_crds\_manifests) | Map of kubectl\_manifest resources for Gateway API CRDs |
| <a name="output_gateway_api_resources_helm_metadata"></a> [gateway\_api\_resources\_helm\_metadata](#output\_gateway\_api\_resources\_helm\_metadata) | Gateway API resources Helm release metadata |
| <a name="output_gateway_helm_metadata"></a> [gateway\_helm\_metadata](#output\_gateway\_helm\_metadata) | Istio gateway Helm release metadata |
| <a name="output_istio_base_helm_metadata"></a> [istio\_base\_helm\_metadata](#output\_istio\_base\_helm\_metadata) | istio-base Helm release metadata |
| <a name="output_istiod_helm_metadata"></a> [istiod\_helm\_metadata](#output\_istiod\_helm\_metadata) | istiod Helm release metadata |
| <a name="output_kiali_manifest"></a> [kiali\_manifest](#output\_kiali\_manifest) | Kiali custom resource manifest |
| <a name="output_kiali_operator_helm_metadata"></a> [kiali\_operator\_helm\_metadata](#output\_kiali\_operator\_helm\_metadata) | Kiali operator Helm release metadata |
<!-- END_TF_DOCS -->
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.0 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | ~> 1.14 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | 2.17.0 |
| <a name="provider_kubectl"></a> [kubectl](#provider\_kubectl) | 1.19.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_gateway_api_crds"></a> [gateway\_api\_crds](#module\_gateway\_api\_crds) | ../gateway-api-crds | n/a |
| <a name="module_kiali"></a> [kiali](#module\_kiali) | ../kiali | n/a |

## Resources

| Name | Type |
|------|------|
| [helm_release.gateway](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.gateway_api_resources](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.istio_base](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.istiod](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubectl_manifest.istio_ingress_class](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_configs"></a> [configs](#input\_configs) | The Istio setup configs | <pre>object({<br/>    chart = optional(object({                                                                    # Global Helm chart defaults for Istio releases (repository/version/namespace and release behavior)<br/>      repository       = optional(string, "https://istio-release.storage.googleapis.com/charts") # global istio helm charts repository<br/>      version          = optional(string, "1.30.3")                                              # fallback version for istio base/gateway/istiod charts<br/>      namespace        = optional(string, "istio-system")                                        # the namespace where istio and related components will be installed<br/>      create_namespace = optional(bool, true)                                                    # whether to create namespace or not<br/>      atomic           = optional(bool, false)                                                   # whether auto rollback if helm install fails<br/>      wait             = optional(bool, true)                                                    # whether wait to get the workload run successfully<br/>      timeout          = optional(number, 300)                                                   # wait timeout in seconds (default 5 minutes)<br/>    }), {})<br/>    image = optional(object({      # global image settings used by Istio components<br/>      registry  = optional(string) # image registry host (for example: docker.io, ghcr.io), default is empty which means it points to "docker.io"<br/>      namespace = optional(string) # image namespace/org path used as hub (for example: istio), default is empty which means it points to "istio<br/>      tag       = optional(string) # image tag shared across Istio components, default is empty which means it points to version from helm chart which usually for istio is the same as the helm chart version<br/>      repository = optional(object({<br/>        istiod = optional(string) # istiod controller image name (helm value `image`), default from chart is usually `pilot` when not set<br/>        proxy  = optional(string) # istio data-plane proxy image name (helm value `global.proxy.image`), default from chart is usually `proxyv2` when not set<br/>      }), {})<br/>    }), {})<br/>    base = optional(object({                        # istio-base configuration<br/>      enabled      = optional(bool, true)           # weather install istio-base helm chart<br/>      name         = optional(string, "istio-base") # the name of istio-base helm release<br/>      chart        = optional(string, "base")       # optional per-component chart name or direct .tgz URL override<br/>      repository   = optional(string)               # optional per-component chart repository override<br/>      version      = optional(string)               # optional per-component chart version override<br/>      values       = optional(any, {})              # helm chart common default configs<br/>      extra_values = optional(any, {})              # helm chart extra configs to pass and extend/use all available options<br/>    }), {})<br/>    istiod = optional(object({                   # istiod configuration<br/>      enabled       = optional(bool, true)       # weather install istiod helm chart<br/>      name          = optional(string, "istiod") # the name of istiod helm release<br/>      chart         = optional(string, "istiod") # optional per-component chart name or direct .tgz URL override<br/>      repository    = optional(string)           # optional per-component chart repository override<br/>      version       = optional(string)           # optional per-component chart version override<br/>      configs       = optional(any, {})          # helm chart common default configs<br/>      extra_configs = optional(any, {})          # helm chart extra configs to pass and extend/use all available options<br/>    }), {})<br/>    gateway = optional(object({        # Gateway configuration (CRDs, Ingress Gateway, and Gateway API resources)<br/>      crds = optional(object({         # k8s Gateway API CRDs configuration<br/>        enabled = optional(bool, true) # whether install Gateway API CRDs, in case if they are not enabled already<br/>      }), {})<br/>      ingress_gateways = optional(list(object({ # istio-gateway (ingress gateway) configurations<br/>        # NOTE: The istio-gateway helm chart is NOT required when using Kubernetes native Gateway API resources.<br/>        # It is only needed when using Istio's custom Gateway API implementation/CRDs (e.g., VirtualService, Gateway CRDs).<br/>        # When using Kubernetes native Gateway API (gateway.networking.k8s.io), the gateway is managed through<br/>        # Kubernetes Gateway resources and the istio-gateway helm chart can be omitted.<br/>        name          = optional(string, "istio-ingressgateway") # helm release name; when defining multiple ingress gateways this must be unique per item<br/>        chart         = optional(string, "gateway")              # optional per-component chart name or direct .tgz URL override<br/>        repository    = optional(string)                         # optional per-component chart repository override<br/>        version       = optional(string)                         # optional per-component chart version override<br/>        configs       = optional(any, {})                        # helm chart common default configs<br/>        extra_configs = optional(any, {})                        # helm chart extra configs to pass and extend/use all available options<br/>        ingress_class = optional(object({                        # Kubernetes IngressClass configuration for Istio ingress<br/>          create = optional(bool, true)                          # whether to create IngressClass resource (default: true)<br/>          name   = optional(string, "istio")                     # must be unique if multiple ingress gateways create ingress classes<br/>        }), {})<br/>      })), [])<br/>      # Wrapper for all gateway-api helm chart objects (Gateways, HTTPRoutes, GRPCRoutes, etc.).<br/>      # Resources will be created in configs.chart.namespace. If gateways list is empty, Gateway API resources release will not be created.<br/>      api_resources = optional(object({<br/>        name             = optional(string, "gateway-api-resources")          # name of the gateway-api resources helm release<br/>        enabled          = optional(bool, true)                               # whether to create the gateway-api resources helm release<br/>        chart            = optional(string, "gateway-api")                    # the gateway-api chart name or direct .tgz URL<br/>        chart_version    = optional(string, "0.1.7")                          # the version of gateway-api chart<br/>        chart_repository = optional(string, "https://dasmeta.github.io/helm") # the repository of gateway-api chart<br/>        gateways         = optional(any, [])                                  # list (or single object) of Gateway resources to create (gateway.networking.k8s.io)<br/>        # Example:<br/>        # gateways = [<br/>        #   {<br/>        #     name = "main"<br/>        #     gatewayClassName = "istio"<br/>        #     listeners = [<br/>        #       { name = "http", hostname = "example.com", port = 80, protocol = "HTTP" }<br/>        #     ]<br/>        #   }<br/>        # ]<br/>        httpRoutes = optional(any, []) # list (or single object) of HTTPRoute resources<br/>        # Example:<br/>        # httpRoutes = [<br/>        #   {<br/>        #     name = "http-to-https-redirect"<br/>        #     parentRefs = [{ name = "main", sectionName = "http-80" }]<br/>        #     hostnames = ["*.example.com"]<br/>        #     rules = [{ redirect = { scheme = "https", statusCode = 301 } }]<br/>        #   }<br/>        # ]<br/>        grpcRoutes = optional(any, []) # list (or single object) of GRPCRoute resources<br/>        # Example:<br/>        # grpcRoutes = [<br/>        #   {<br/>        #     name = "grpc-service"<br/>        #     parentRefs = [{ name = "main" }]<br/>        #     hostnames = ["grpc.example.com"]<br/>        #     rules = [{<br/>        #       matches = [{ method = { type = "Exact", service = "my.Service", method = "Get" } }]<br/>        #       backendRefs = [{ name = "my-service", port = 50051 }]<br/>        #     }]<br/>        #   }<br/>        # ]<br/>        tcpRoutes = optional(any, []) # list (or single object) of TCPRoute resources (experimental CRDs)<br/>        tlsRoutes = optional(any, []) # list (or single object) of TLSRoute resources (experimental CRDs)<br/>        udpRoutes = optional(any, []) # list (or single object) of UDPRoute resources (experimental CRDs)<br/>        istio     = optional(any, {}) # Istio-specific resources (AuthorizationPolicy, VirtualService, etc.)<br/>        # Example:<br/>        # istio = {<br/>        #   defaultTargetRefs = [{ name = "main", namespace = "istio-system" }]<br/>        #   authorizationPolicies = [{<br/>        #     name = "block-admin"<br/>        #     targetRefs = [{ name = "main" }]<br/>        #     rules = [{ to = [{ operation = { paths = ["/admin*"] } }] }]<br/>        #   }]<br/>        #   virtualServices = [{<br/>        #     name = "my-vs", hosts = ["example.com"], gateways = ["istio-system/main"]<br/>        #     http = [{ match = [{ uri = { prefix = "/api" } }], route = [{ destination = { host = "my-service", port = { number = 80 } } }] }]<br/>        #   }]<br/>        # }<br/>      }), {})<br/>    }), {})<br/>    kiali = optional(object({<br/>      enabled = optional(bool, false) # whether to deploy Kiali observability components<br/>      operator = optional(object({<br/>        enabled          = optional(bool, true)                              # whether to install the Kiali operator Helm chart<br/>        name             = optional(string, "kiali-operator")                # the Kiali operator Helm release name<br/>        namespace        = optional(string, null)                            # the namespace where the Kiali operator will be installed; defaults to configs.chart.namespace<br/>        chart            = optional(string, "kiali-operator")                # the Kiali operator chart name or direct .tgz URL<br/>        chart_repository = optional(string, "https://kiali.org/helm-charts") # Kiali operator Helm chart repository<br/>        chart_version    = optional(string, "2.29.0")                        # optional Kiali operator chart version<br/>        create_namespace = optional(bool, true)                              # whether Helm should create the operator namespace<br/>        atomic           = optional(bool, false)                             # whether Helm should roll back on failure<br/>        wait             = optional(bool, true)                              # whether Helm should wait for resources to become ready<br/>        image = optional(object({<br/>          registry  = optional(string) # shared image registry host for Kiali operator/server (example: quay.io, ghcr.io)<br/>          namespace = optional(string) # shared image namespace/org path for Kiali operator/server (example: kiali)<br/>          tag       = optional(string) # shared image tag used for both Kiali operator and server images<br/>          # `allowAdHocKialiImage` is auto-enabled internally when server image override is used.<br/>          repository = optional(object({<br/>            operator = optional(string) # operator image repository name/path (without registry/namespace)<br/>            server   = optional(string) # server image repository name/path (without registry/namespace)<br/>          }), {})<br/>        }), {})<br/>        values       = optional(any, {}) # Kiali operator chart values<br/>        extra_values = optional(any, {}) # extra Kiali operator chart values<br/>      }), {})<br/>      cr = optional(object({<br/>        enabled        = optional(bool, true)          # whether to create a Kiali custom resource<br/>        name           = optional(string, "kiali")     # the Kiali custom resource name<br/>        namespace      = optional(string, null)        # the Kiali custom resource namespace; defaults to configs.chart.namespace when called through Istio<br/>        labels         = optional(map(string), {})     # labels applied to the Kiali custom resource<br/>        annotations    = optional(map(string), {})     # annotations applied to the Kiali custom resource<br/>        auth_strategy  = optional(string, "anonymous") # Kiali auth strategy<br/>        view_only_mode = optional(bool, false)         # whether Kiali should run in view-only mode<br/>        deployment     = optional(any, {})             # Kiali spec.deployment overrides<br/>        external_services = optional(object({<br/>          prometheus = optional(object({<br/>            url              = optional(string)      # Prometheus internal service URL used by Kiali<br/>            auth             = optional(any)         # Prometheus auth configuration<br/>            custom_headers   = optional(map(string)) # custom headers sent to Prometheus<br/>            health_check_url = optional(string)      # optional Prometheus health check URL<br/>            is_core          = optional(bool)        # whether Prometheus is a core service<br/>            query_scope      = optional(map(string)) # query scope labels such as mesh_id or cluster<br/>            thanos_proxy     = optional(any)         # Thanos proxy configuration<br/>            extra_configs    = optional(any, {})     # extra Prometheus settings merged into spec.external_services.prometheus<br/>          }), {})<br/>          grafana = optional(object({<br/>            enabled          = optional(bool)      # whether Grafana integration is enabled<br/>            internal_url     = optional(string)    # Grafana URL reachable inside the cluster<br/>            external_url     = optional(string)    # Grafana URL opened by users from Kiali<br/>            datasource_uid   = optional(string)    # Grafana datasource UID for Prometheus<br/>            dashboards       = optional(list(any)) # Grafana dashboard definitions used by Kiali links<br/>            auth             = optional(any)       # Grafana auth configuration<br/>            health_check_url = optional(string)    # optional Grafana health check URL<br/>            is_core          = optional(bool)      # whether Grafana is a core service<br/>            extra_configs    = optional(any, {})   # extra Grafana settings merged into spec.external_services.grafana<br/>          }), {})<br/>        }), {})<br/>        spec = optional(any, {}) # extra Kiali CR spec values; overrides generated common-case fields on key conflict<br/>      }), {})<br/>    }), {})<br/>  })</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_gateway_api_crds_manifests"></a> [gateway\_api\_crds\_manifests](#output\_gateway\_api\_crds\_manifests) | Map of kubectl\_manifest resources for Gateway API CRDs |
| <a name="output_gateway_api_resources_helm_metadata"></a> [gateway\_api\_resources\_helm\_metadata](#output\_gateway\_api\_resources\_helm\_metadata) | Gateway API resources Helm release metadata |
| <a name="output_gateway_helm_metadata"></a> [gateway\_helm\_metadata](#output\_gateway\_helm\_metadata) | Istio gateway Helm release metadata |
| <a name="output_istio_base_helm_metadata"></a> [istio\_base\_helm\_metadata](#output\_istio\_base\_helm\_metadata) | istio-base Helm release metadata |
| <a name="output_istiod_helm_metadata"></a> [istiod\_helm\_metadata](#output\_istiod\_helm\_metadata) | istiod Helm release metadata |
| <a name="output_kiali_manifest"></a> [kiali\_manifest](#output\_kiali\_manifest) | Kiali custom resource manifest |
| <a name="output_kiali_operator_helm_metadata"></a> [kiali\_operator\_helm\_metadata](#output\_kiali\_operator\_helm\_metadata) | Kiali operator Helm release metadata |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
