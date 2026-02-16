# istio

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.0 |
| <a name="requirement_http"></a> [http](#requirement\_http) | ~> 3.0 |
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
| <a name="input_configs"></a> [configs](#input\_configs) | The Istio setup configs | <pre>object({<br/>    repository       = optional(string, "https://istio-release.storage.googleapis.com/charts") # The istio helm charts repository<br/>    namespace        = optional(string, "istio-system")                                        # the namespace where istio and related components will be installed<br/>    create_namespace = optional(bool, true)                                                    # whether to create namespace or not<br/>    atomic           = optional(bool, false)                                                   # whether auto rollback if helm install fails<br/>    wait             = optional(bool, true)                                                    # whether wait to get the workload run successfully<br/>    base = optional(object({                                                                   # istio-base configuration<br/>      enabled       = optional(bool, true)                                                     # weather install istio-base helm chart<br/>      name          = optional(string, "istio-base")                                           # the name of istio-base helm release<br/>      chart_version = optional(string, "1.28.3")                                               # the version of istio-base chart<br/>      values        = optional(any, {})                                                        # helm chart common default configs<br/>      extra_values  = optional(any, {})                                                        # helm chart extra configs to pass and extend/use all available options<br/>    }), {})<br/>    istiod = optional(object({                   # istiod configuration<br/>      enabled       = optional(bool, true)       # weather install istiod helm chart<br/>      name          = optional(string, "istiod") # the name of istiod helm release<br/>      chart_version = optional(string, "1.28.3") # the version of istio-base chart<br/>      configs       = optional(any, {})          # helm chart common default configs<br/>      extra_configs = optional(any, {})          # helm chart extra configs to pass and extend/use all available options<br/>    }), {})<br/>    gateway = optional(object({              # Gateway configuration (CRDs, Ingress Gateway, and Gateway API resources)<br/>      crds = optional(object({               # k8s Gateway API CRDs configuration<br/>        enabled = optional(bool, true)       # whether install Gateway API CRDs, in case if they are not enabled already<br/>        version = optional(string, "v1.4.1") # the Gateway API CRDs version (e.g., v1.4.1, v1.1.0)<br/>      }), {})<br/>      ingressgateway = optional(object({ # istio-gateway (ingress gateway) configuration<br/>        # NOTE: The istio-gateway helm chart is NOT required when using Kubernetes native Gateway API resources.<br/>        # It is only needed when using Istio's custom Gateway API implementation/CRDs (e.g., VirtualService, Gateway CRDs).<br/>        # When using Kubernetes native Gateway API (gateway.networking.k8s.io), the gateway is managed through<br/>        # Kubernetes Gateway resources and the istio-gateway helm chart should be disabled (enabled = false).<br/>        # Additionally, the istio-gateway helm chart is also used for Istio ingress creation and management.<br/>        # When enabled, it provides the ingress gateway service that can be used with Kubernetes Ingress resources<br/>        # (via IngressClass) to route traffic into the Istio service mesh.<br/>        enabled       = optional(bool, false)                    # whether install istio-gateway helm chart (default: false, not needed for native Gateway API)<br/>        name          = optional(string, "istio-ingressgateway") # the name of istio-gateway helm release<br/>        chart_version = optional(string, "1.28.3")               # the version of istio-gateway chart<br/>        configs       = optional(any, {})                        # helm chart common default configs<br/>        extra_configs = optional(any, {})                        # helm chart extra configs to pass and extend/use all available options<br/>        ingress_class = optional(object({                        # Kubernetes IngressClass configuration for Istio ingress<br/>          create = optional(bool, true)                          # whether to create IngressClass resource (default: true)<br/>          name   = optional(string, "istio")                     # the name of the IngressClass (default: "istio")<br/>        }), {})                                                  # This IngressClass allows Kubernetes Ingress resources to use Istio's ingress gateway<br/>      }), {})<br/>      items = optional(any, []) # list (or single object) of Gateway resources to create<br/>      # This creates native Kubernetes Gateway API resources (gateway.networking.k8s.io) using the gateway-api helm chart.<br/>      # These resources work with Istio when Gateway API CRDs are installed and istiod is running.<br/>      # This is the recommended approach for managing ingress traffic when using Istio with native Gateway API.<br/>      # The chart path and release name are hardcoded. Resources will be created in configs.namespace.<br/>      # If the list is empty, Gateway API resources will not be created.<br/>      # Example:<br/>      # items = [<br/>      #   {<br/>      #     name = "main"<br/>      #     gatewayClassName = "istio"<br/>      #     listeners = [<br/>      #       {<br/>      #         name = "http"<br/>      #         hostname = "example.com"<br/>      #         port = 80<br/>      #         protocol = "HTTP"<br/>      #       }<br/>      #     ]<br/>      #   }<br/>      # ]<br/>    }), {})<br/>  })</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_gateway_api_crds_manifests"></a> [gateway\_api\_crds\_manifests](#output\_gateway\_api\_crds\_manifests) | Map of kubectl\_manifest resources for Gateway API CRDs |
| <a name="output_gateway_api_resources_helm_metadata"></a> [gateway\_api\_resources\_helm\_metadata](#output\_gateway\_api\_resources\_helm\_metadata) | Gateway API resources Helm release metadata |
| <a name="output_gateway_helm_metadata"></a> [gateway\_helm\_metadata](#output\_gateway\_helm\_metadata) | Istio gateway Helm release metadata |
| <a name="output_istio_base_helm_metadata"></a> [istio\_base\_helm\_metadata](#output\_istio\_base\_helm\_metadata) | istio-base Helm release metadata |
| <a name="output_istiod_helm_metadata"></a> [istiod\_helm\_metadata](#output\_istiod\_helm\_metadata) | istiod Helm release metadata |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
