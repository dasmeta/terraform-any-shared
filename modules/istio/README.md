# istio

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | ~> 2.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.gateway](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.gateway_api_crds](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.istio_base](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.istiod](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_configs"></a> [configs](#input\_configs) | The Istio setup configs | <pre>object({<br/>    repository       = optional(string, "https://istio-release.storage.googleapis.com/charts") # The istio helm charts repository<br/>    namespace        = optional(string, "istio-system")                                        # the namespace where istio and related components will be installed<br/>    create_namespace = optional(bool, true)                                                    # whether to create namespace or not<br/>    atomic           = optional(bool, false)                                                   # whether auto rollback if helm install fails<br/>    wait             = optional(bool, true)                                                    # whether wait to get the workload run successfully<br/>    gateway_api_crds = optional(object({                                                       # k8s Gateway API crds<br/>      enabled       = optional(bool, true)                                                     # whether install crds, in case if they are not enabled already<br/>      name          = optional(string, "gateway-api-crds")                                     # the name of gateway-api-crds helm release<br/>      chart         = optional(string, "gateway-api-crds")                                     # the chart name for gateway-api-crds<br/>      chart_version = optional(string, "1.28.3")                                               # the chart version for gateway-api-crds<br/>    }))<br/>    base = optional(object({                         # istio-base configuration<br/>      enabled       = optional(bool, true)           # weather install istio-base helm chart<br/>      name          = optional(string, "istio-base") # the name of istio-base helm release<br/>      chart_version = optional(string, "1.28.3")     # the version of istio-base chart<br/>      values        = optional(any, {})              # helm chart common default configs<br/>      extra_values  = optional(any, {})              # helm chart extra configs to pass and extend/use all available options<br/>    }))<br/>    istiod = optional(object({                   # istiod configuration<br/>      enabled       = optional(bool, true)       # weather install istiod helm chart<br/>      name          = optional(string, "istiod") # the name of istiod helm release<br/>      chart_version = optional(string, "1.28.3") # the version of istio-base chart<br/>      configs       = optional(any, {})          # helm chart common default configs<br/>      extra_configs = optional(any, {})          # helm chart extra configs to pass and extend/use all available options<br/>    }))<br/>    gateway = optional(object({                         # istio-gateway configuration<br/>      enabled       = optional(bool, true)              # weather install istio-gateway helm chart<br/>      name          = optional(string, "istio-gateway") # the name of istio-gateway helm release<br/>      chart_version = optional(string, "1.28.3")        # the version of istio-base chart<br/>      configs       = optional(any, {})                 # helm chart common default configs<br/>      extra_configs = optional(any, {})                 # helm chart extra configs to pass and extend/use all available options<br/>    }))<br/>  })</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_gateway_api_crds_helm_metadata"></a> [gateway\_api\_crds\_helm\_metadata](#output\_gateway\_api\_crds\_helm\_metadata) | Gateway API CRDs Helm release metadata |
| <a name="output_gateway_helm_metadata"></a> [gateway\_helm\_metadata](#output\_gateway\_helm\_metadata) | Istio gateway Helm release metadata |
| <a name="output_istio_base_helm_metadata"></a> [istio\_base\_helm\_metadata](#output\_istio\_base\_helm\_metadata) | istio-base Helm release metadata |
| <a name="output_istiod_helm_metadata"></a> [istiod\_helm\_metadata](#output\_istiod\_helm\_metadata) | istiod Helm release metadata |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
