# service

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.service](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_chart"></a> [chart](#input\_chart) | The name of the Helm chart to deploy. | `string` | `"base"` | no |
| <a name="input_helm_values"></a> [helm\_values](#input\_helm\_values) | Values which is overwrite chart defaults | `any` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Service names | `string` | n/a | yes |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace | `string` | n/a | yes |
| <a name="input_repository"></a> [repository](#input\_repository) | The URL of the Helm chart repository. | `string` | `"https://dasmeta.github.io/helm/"` | no |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
