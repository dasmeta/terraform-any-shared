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
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 4.37.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.37.0 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.renovate](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [aws_eks_cluster.cluster](https://registry.terraform.io/providers/hashicorp/aws/4.37.0/docs/data-sources/eks_cluster) | data source |
| [aws_eks_cluster_auth.cluster](https://registry.terraform.io/providers/hashicorp/aws/4.37.0/docs/data-sources/eks_cluster_auth) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_autodiscover"></a> [autodiscover](#input\_autodiscover) | Autodiscover all repositories. | `string` | `true` | no |
| <a name="input_branch_name"></a> [branch\_name](#input\_branch\_name) | n/a | `string` | `"renovate-configure"` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | For provider | `string` | n/a | yes |
| <a name="input_endpoint"></a> [endpoint](#input\_endpoint) | Custom endpoint to use. | `string` | `"https://gitlab.example.com/api/v4"` | no |
| <a name="input_github_token"></a> [github\_token](#input\_github\_token) | GitHub Personal Access token | `string` | n/a | yes |
| <a name="input_host_rules"></a> [host\_rules](#input\_host\_rules) | List of renovate [hostRules](https://docs.renovatebot.com/configuration-options/#hostrules). | <pre>list(object({<br>    hostType  = string<br>    token     = string<br>    matchHost = string<br>  }))</pre> | `[]` | no |
| <a name="input_name"></a> [name](#input\_name) | Helm release name | `string` | `"renovate"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Helm release namespace | `string` | `"renovate"` | no |
| <a name="input_package_rules"></a> [package\_rules](#input\_package\_rules) | List of renovate [packageRules](https://docs.renovatebot.com/configuration-options/#packagerules). | <pre>list(object({<br>    matchDatasources            = optional(list(string))<br>    matchPackageNames           = optional(list(string))<br>    matchPackagePatterns        = optional(list(string))<br>    matchPaths                  = optional(list(string))<br>    extends                     = optional(list(string))<br>    registryUrls                = optional(list(string))<br>    groupName                   = optional(string)<br>    schedule                    = optional(string)<br>    dependencyDashboardApproval = optional(bool)<br>  }))</pre> | `[]` | no |
| <a name="input_platform"></a> [platform](#input\_platform) | Platform type of repository. | `string` | `"gitlab"` | no |
| <a name="input_schedule"></a> [schedule](#input\_schedule) | Bot working shedule. | `string` | `"0 1 * * *"` | no |
| <a name="input_token"></a> [token](#input\_token) | GitLab Personal Access token | `string` | n/a | yes |
| <a name="input_version"></a> [version](#input\_version) | Helm release version | `string` | `"41.42.2"` | no |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
