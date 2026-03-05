### Automated dependency updates. Multi-platform and multi-language.

## Module Usage for GitLab
```
module "renovate-bot" {
    source = "dasmeta/shared/any//modules/renovate-bot"

    platform = "gitlab"
    endpoint = "https://gitlab.example.com/api/v4"

    token    = "**********"
    github_token = "**********"
    schedule = "0 1 * * *"
    autodiscover  = true

    cluster_name = "eks"

    # optional
    host_rules = [
        {
          matchHost = "https://some.private.registry",
          token     = "**********",
          hostType  = "npm"
        }
    ]

    # optional
    package_rules = [
      {
        matchDatasources  = ["maven"],
        matchPackageNames = ["somepackage"],
        registryUrls      = ["https://some.private.registry"],
      }
    ]
}
```
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
| <a name="input_autodiscover"></a> [autodiscover](#input\_autodiscover) | Autodiscover all repositories the token can access. | `bool` | `true` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | The Renovate Helm chart version to use. | `string` | `"46.52.2"` | no |
| <a name="input_create_namespace"></a> [create\_namespace](#input\_create\_namespace) | Create the namespace if it does not exist. | `bool` | `true` | no |
| <a name="input_custom_configs"></a> [custom\_configs](#input\_custom\_configs) | Additional or override values for the Helm chart. Merged on top of default values. See Renovate Helm chart documentation. | `any` | `{}` | no |
| <a name="input_endpoint"></a> [endpoint](#input\_endpoint) | Platform API endpoint (e.g. https://gitlab.com/api/v4). | `string` | `"https://gitlab.com/api/v4"` | no |
| <a name="input_extra_config"></a> [extra\_config](#input\_extra\_config) | Optional JSON object merged into Renovate config. Use for self-hosted-only options (e.g. allowScripts, allowedCommands) or shared defaults. See https://docs.renovatebot.com/self-hosted-configuration/ | `string` | `"{}"` | no |
| <a name="input_github_token"></a> [github\_token](#input\_github\_token) | GitHub Personal Access token (for fetching release notes etc.). | `string` | n/a | yes |
| <a name="input_host_rules"></a> [host\_rules](#input\_host\_rules) | List of Renovate hostRules (private registries, auth). See https://docs.renovatebot.com/configuration-options/#hostrules. | <pre>list(object({<br/>    matchHost = string<br/>    token     = string<br/>    hostType  = string<br/>  }))</pre> | `[]` | no |
| <a name="input_name"></a> [name](#input\_name) | The name of the Helm release. | `string` | `"renovate"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | The Kubernetes namespace to install Renovate. | `string` | `"renovate"` | no |
| <a name="input_onboarding_branch"></a> [onboarding\_branch](#input\_onboarding\_branch) | Branch name used for onboarding PRs (e.g. renovate-configure). | `string` | `"renovate-configure"` | no |
| <a name="input_package_rules"></a> [package\_rules](#input\_package\_rules) | List of Renovate packageRules. See https://docs.renovatebot.com/configuration-options/#packagerules. | <pre>list(object({<br/>    matchDatasources            = optional(list(string))<br/>    matchPackageNames           = optional(list(string))<br/>    matchPackagePatterns        = optional(list(string))<br/>    matchPaths                  = optional(list(string))<br/>    extends                     = optional(list(string))<br/>    registryUrls                = optional(list(string))<br/>    groupName                   = optional(string)<br/>    schedule                    = optional(string)<br/>    dependencyDashboardApproval = optional(bool)<br/>  }))</pre> | `[]` | no |
| <a name="input_platform"></a> [platform](#input\_platform) | Platform type (e.g. gitlab, github). | `string` | `"gitlab"` | no |
| <a name="input_schedule"></a> [schedule](#input\_schedule) | Cron schedule for the Renovate CronJob (e.g. '0 1 * * *' for daily at 01:00). | `string` | `"0 1 * * *"` | no |
| <a name="input_token"></a> [token](#input\_token) | Platform Personal Access token (GitLab/GitHub etc.). | `string` | n/a | yes |
| <a name="input_wait"></a> [wait](#input\_wait) | Wait for the release to be deployed successfully. | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_helm_metadata"></a> [helm\_metadata](#output\_helm\_metadata) | Renovate Helm release metadata |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
