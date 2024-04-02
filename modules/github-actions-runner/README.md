# Setup github actions runner in k8s,
# By default, actions-runner-controller uses cert-manager for certificate management of Admission Webhook
# You can install cert manager 'kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.7.1/cert-manager.yaml'


# Example 1

```
module "action-runner" {
  source                = "dasmeta/shared/any//modules/github-actions-runner"
  personal_access_token = "ghp_ZhJoqzL******M6FCk"
  kubectl_config_path   = "~/.kube/config"
  repo_name             = "tutor-platform/action-runner"
  runner_name           = "runner"
}
```
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | n/a |
| <a name="provider_kubectl"></a> [kubectl](#provider\_kubectl) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.test](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubectl_manifest.pv_mongo_main](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_path_documents.docs](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/data-sources/path_documents) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_kubectl_config_path"></a> [kubectl\_config\_path](#input\_kubectl\_config\_path) | K8s config path | `string` | `"~/.kube/config"` | no |
| <a name="input_personal_access_token"></a> [personal\_access\_token](#input\_personal\_access\_token) | personal access token | `string` | n/a | yes |
| <a name="input_repo_name"></a> [repo\_name](#input\_repo\_name) | Repository Name | `string` | `"tutor-platform/ncet-infrastructure"` | no |
| <a name="input_runner_name"></a> [runner\_name](#input\_runner\_name) | Runner Name | `string` | `"runner"` | no |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
