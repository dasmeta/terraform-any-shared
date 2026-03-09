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
| <a name="provider_helm"></a> [helm](#provider\_helm) | 2.17.0 |

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
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | The Renovate Helm chart version to use. | `string` | `"46.52.2"` | no |
| <a name="input_create_namespace"></a> [create\_namespace](#input\_create\_namespace) | Create the namespace if it does not exist. | `bool` | `true` | no |
| <a name="input_helm_extra_configs"></a> [helm\_extra\_configs](#input\_helm\_extra\_configs) | Additional or override values for the Helm chart. Merged on top of default values. See Renovate Helm chart documentation. | `any` | `{}` | no |
| <a name="input_name"></a> [name](#input\_name) | The name of the Helm release. | `string` | `"renovate"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | The Kubernetes namespace to install Renovate. | `string` | `"renovate"` | no |
| <a name="input_renovate_configs"></a> [renovate\_configs](#input\_renovate\_configs) | Renovate bot configuration (keys match Renovate's config format). Override only the keys you need (e.g. platform = "github"); the rest use defaults. | <pre>object({<br/>    platform         = optional(string, "gitlab")<br/>    endpoint         = optional(string, "https://gitlab.com/api/v4")<br/>    token            = optional(string, "")<br/>    github_token     = optional(string, "")<br/>    autodiscover     = optional(bool, true)<br/>    onboardingBranch = optional(string, "renovate-configure")<br/>    schedule         = optional(string, "0 1 * * *")<br/>    hostRules = optional(list(object({<br/>      matchHost = string<br/>      token     = string<br/>      hostType  = string<br/>    })), [])<br/>    packageRules = optional(list(object({<br/>      matchDatasources            = optional(list(string))<br/>      matchPackageNames           = optional(list(string))<br/>      matchPackagePatterns        = optional(list(string))<br/>      matchPaths                  = optional(list(string))<br/>      extends                     = optional(list(string))<br/>      registryUrls                = optional(list(string))<br/>      groupName                   = optional(string)<br/>      schedule                    = optional(string)<br/>      dependencyDashboardApproval = optional(bool)<br/>    })), [])<br/>  })</pre> | `{}` | no |
| <a name="input_renovate_extra_configs"></a> [renovate\_extra\_configs](#input\_renovate\_extra\_configs) | Extra Renovate config options not covered by renovate\_configs (e.g. onboarding, requireConfig). Merged into the final config. See https://docs.renovatebot.com/self-hosted-configuration/ | `any` | `{}` | no |
| <a name="input_wait"></a> [wait](#input\_wait) | Wait for the release to be deployed successfully. | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_helm_metadata"></a> [helm\_metadata](#output\_helm\_metadata) | Renovate Helm release metadata |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
