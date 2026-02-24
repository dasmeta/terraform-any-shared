# defectdojo

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
| [helm_release.this](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_atomic"></a> [atomic](#input\_atomic) | If set, the installation process will be rolled back on failure. | `bool` | `false` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | The DefectDojo Helm chart version to use. | `string` | `"1.9.14"` | no |
| <a name="input_create_namespace"></a> [create\_namespace](#input\_create\_namespace) | Create the namespace if it does not exist. | `bool` | `true` | no |
| <a name="input_custom_configs"></a> [custom\_configs](#input\_custom\_configs) | Additional or override values for the Helm chart. Merged on top of default\_configs. See https://artifacthub.io/packages/helm/defectdojo/defectdojo?modal=values | `any` | `{}` | no |
| <a name="input_default_configs"></a> [default\_configs](#input\_default\_configs) | Default values to pass to the Helm chart. Override specific fields via custom\_configs. | `any` | <pre>{<br/>  "createPostgresqlSecret": true,<br/>  "createSecret": true,<br/>  "createValkeySecret": true<br/>}</pre> | no |
| <a name="input_name"></a> [name](#input\_name) | The name of the Helm release. | `string` | `"defectdojo"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | The Kubernetes namespace to install DefectDojo. | `string` | `"defectdojo"` | no |
| <a name="input_wait"></a> [wait](#input\_wait) | Wait for the release to be deployed successfully. | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_helm_metadata"></a> [helm\_metadata](#output\_helm\_metadata) | DefectDojo Helm release metadata |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
