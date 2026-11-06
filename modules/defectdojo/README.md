# defectdojo

Deploys DefectDojo into Kubernetes with an opinionated Helm-based baseline.
Use this module when you need a shared security-testing installation with a
small input surface and override-friendly chart configuration.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | 2.17.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.retention](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.retention_bootstrap](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.this](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_atomic"></a> [atomic](#input\_atomic) | If set, the installation process will be rolled back on failure. | `bool` | `false` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | The DefectDojo Helm chart version to use. | `string` | `"1.9.64"` | no |
| <a name="input_create_namespace"></a> [create\_namespace](#input\_create\_namespace) | Create the namespace if it does not exist. | `bool` | `true` | no |
| <a name="input_custom_configs"></a> [custom\_configs](#input\_custom\_configs) | Additional or override values for the Helm chart. Merged on top of default\_configs. See https://artifacthub.io/packages/helm/defectdojo/defectdojo?modal=values | `any` | `{}` | no |
| <a name="input_default_configs"></a> [default\_configs](#input\_default\_configs) | Default values to pass to the Helm chart. Override specific fields via custom\_configs. | `any` | <pre>{<br/>  "createPostgresqlSecret": true,<br/>  "createSecret": true,<br/>  "createValkeySecret": true<br/>}</pre> | no |
| <a name="input_name"></a> [name](#input\_name) | The name of the Helm release. | `string` | `"defectdojo"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | The Kubernetes namespace to install DefectDojo. | `string` | `"defectdojo"` | no |
| <a name="input_retention"></a> [retention](#input\_retention) | Opt-in cleanup of inactive completed Trivy feature Tests without active findings. Select exactly one of engagement\_ids, exact unique engagement\_names or explicit all\_engagements. Requires Kubernetes >=1.27 and API base URL. Supply an existing API token Secret or enable api\_token\_secret.create to bootstrap one from the chart account. See README for permissions and concurrency limitations. | <pre>object({<br/>    enabled   = optional(bool, false)<br/>    days      = optional(number, 30)<br/>    schedule  = optional(string, "17 2 * * *")<br/>    time_zone = optional(string, "Etc/UTC")<br/>    api_url   = optional(string, "")<br/>    api_token_secret = optional(object({<br/>      create = optional(bool, false)<br/>      name   = optional(string, "")<br/>      key    = optional(string, "api-key")<br/>    }), {})<br/>    engagement_ids         = optional(set(number), [])<br/>    engagement_names       = optional(set(string), [])<br/>    all_engagements        = optional(bool, false)<br/>    protected_branches     = optional(set(string), [])<br/>    protected_environments = optional(set(string), [])<br/>    max_tests_per_run      = optional(number, 10)<br/>  })</pre> | `{}` | no |
| <a name="input_wait"></a> [wait](#input\_wait) | Wait for the release to be deployed successfully. | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_helm_metadata"></a> [helm\_metadata](#output\_helm\_metadata) | DefectDojo Helm release metadata |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
