# SETUP gitlab-runner in k8s

# Example 1

```
module "action-runner" {
  source                        = "dasmeta/shared/any//modules/gitlab-runner"
  version                       = "0.1.0"

  kubectl_config_path           = "~/.kube/config"
  runner_name                   = "gitlab-runner"
  runnerRegistrationToken       = "Gj*******"
  gitlab_access_token           = "gj*******"

}
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | 2.7.0 |
| <a name="provider_kubectl"></a> [kubectl](#provider\_kubectl) | 1.14.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.test](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubectl_manifest.values_yaml](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_path_documents.values](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/data-sources/path_documents) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_gitlab_access_token"></a> [gitlab\_access\_token](#input\_gitlab\_access\_token) | Personal Access Token | `string` | `""` | no |
| <a name="input_kubectl_config_path"></a> [kubectl\_config\_path](#input\_kubectl\_config\_path) | K8s config path | `string` | `"~/.kube/config"` | no |
| <a name="input_runnerRegistrationToken"></a> [runnerRegistrationToken](#input\_runnerRegistrationToken) | gitlab runner registration token | `string` | `""` | no |
| <a name="input_runner_name"></a> [runner\_name](#input\_runner\_name) | Runner Name | `string` | `"gitlab-runner"` | no |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
