## MongoDB BI Connector
This module creates a helm release for MongoDB BI Connector Helm chart.


## How to Use
All default values are set by Helm chart. You just need to pass auth parameters and URI for MongoDB to make it work.
Be aware of publishing those credentials. Get sure you pass them in a secure way and not in plain text.
For example:
```
module "mongodb_bi_connector" {
  source = "../../"

  name             = "mongodb-bi-connector-terraform"
  mongodb_username = some_secret_store.mongodb-bi-connector-secret["username"]
  mongodb_password = some_secret_store.mongodb-bi-connector-secret["password"]
  mongodb_uri      = some_secret_store.mongodb-bi-connector-secret["uri"]
}
```
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.14.11 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.4.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | >= 2.4.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.mongodb_bi_connector](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_mongodb_password"></a> [mongodb\_password](#input\_mongodb\_password) | MongoDB password. | `string` | n/a | yes |
| <a name="input_mongodb_uri"></a> [mongodb\_uri](#input\_mongodb\_uri) | MongoDB URI. | `string` | n/a | yes |
| <a name="input_mongodb_username"></a> [mongodb\_username](#input\_mongodb\_username) | MongoDB username. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Release name. | `string` | `"mongodb-bi-connector"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Release namespace. | `string` | `"default"` | no |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
