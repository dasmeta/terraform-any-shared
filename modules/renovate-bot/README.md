### Automated dependency updates. Multi-platform and multi-language.

## Module Usage for GitLab
```
module "renovate-bot" {
    source = "./"
    
    platform = "gitlab"
    endpoint = "https://gitlab.example.com/api/v4"
    
    token    = "**********"
    schedule = "0 1 * * *"
    autodiscover  = true
}
```
<!-- BEGIN_TF_DOCS -->
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
| [helm_release.renovate](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_autodiscover"></a> [autodiscover](#input\_autodiscover) | Autodiscover all repositories. | `string` | `true` | no |
| <a name="input_endpoint"></a> [endpoint](#input\_endpoint) | Custom endpoint to use. | `string` | `"https://gitlab.example.com/api/v4"` | no |
| <a name="input_platform"></a> [platform](#input\_platform) | Platform type of repository. | `string` | `"gitlab"` | no |
| <a name="input_schedule"></a> [schedule](#input\_schedule) | Bot working shedule. | `string` | `"0 1 * * *"` | no |
| <a name="input_token"></a> [token](#input\_token) | Personal Access token | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->