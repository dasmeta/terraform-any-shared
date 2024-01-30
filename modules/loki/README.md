# loki

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | 2.12.1 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_loki"></a> [loki](#module\_loki) | terraform-module/release/helm | 2.8.1 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Loki-stack grafana chart version | `string` | `"2.10.1"` | no |
| <a name="input_loki_storage"></a> [loki\_storage](#input\_loki\_storage) | Loki-Stack storage bucket configs | <pre>object({<br>    type              = string<br>    access_key        = optional(string, "")<br>    secret_access_key = optional(string, "")<br>    bucketname        = optional(string, "")<br>    endpoint          = optional(string, "")<br>    region            = optional(string, "")<br>    cache_ttl         = optional(string, "168h")<br>    period            = optional(string, "24h")<br>  })</pre> | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Chart name | `string` | `"loki"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | n/a | `string` | `"loki-stack"` | no |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
