### Automated dependency updates. Multi-platform and multi-language.

## Module Usage for GitLab
```
module "renovate-bot" {
    source = "dasmeta/shared/any//modules/renovate-bot"
    
    platform = "gitlab"
    endpoint = "https://gitlab.example.com/api/v4"
    
    token    = "**********"
    schedule = "0 1 * * *"
    autodiscover  = true

    cluster_host = ""
    cluster_ca_certificate = ""
    cluster_token = ""
}
```
<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | 2.7.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.renovate](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_autodiscover"></a> [autodiscover](#input\_autodiscover) | Autodiscover all repositories. | `string` | `true` | no |
| <a name="input_cluster_ca_certificate"></a> [cluster\_ca\_certificate](#input\_cluster\_ca\_certificate) | Cluster certificate for helm provider | `string` | n/a | yes |
| <a name="input_cluster_host"></a> [cluster\_host](#input\_cluster\_host) | Cluster host for helm provider | `string` | n/a | yes |
| <a name="input_cluster_token"></a> [cluster\_token](#input\_cluster\_token) | Cluster token for helm provider | `string` | n/a | yes |
| <a name="input_endpoint"></a> [endpoint](#input\_endpoint) | Custom endpoint to use. | `string` | `"https://gitlab.example.com/api/v4"` | no |
| <a name="input_name"></a> [name](#input\_name) | Helm release name | `string` | `"renovate"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Helm release namespace | `string` | `"renovate"` | no |
| <a name="input_platform"></a> [platform](#input\_platform) | Platform type of repository. | `string` | `"gitlab"` | no |
| <a name="input_schedule"></a> [schedule](#input\_schedule) | Bot working shedule. | `string` | `"0 1 * * *"` | no |
| <a name="input_token"></a> [token](#input\_token) | Personal Access token | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->