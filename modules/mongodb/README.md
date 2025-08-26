# This module intended to add MongoDB  in onpremise kubernetes setup and will do the following:
* Default will created mongodb replicaset if you want change setup standalone please change from variables.tf file
* If created with replicaset pods will created with statesfulset, if change setup type standalone pods will created with deployments


## Example 1

```
module "mongodb" {
  source  = "dasmeta/shared/any//modules/mongodb"
  version = "0.2.1"
}
```

## Example 2

```
module "mongodb" {
  source  = "dasmeta/shared/any//modules/mongodb"
  version = "0.2.1"

  root_password  = ""
  replicaset_key = ""
  resources_requests = {
    cpu    = "250m"
    memory = "64Mi"
  }
  resources_limits = {
    cpu    = "500m"
    memory = "128Mi"
  }
}
```
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

No requirements.

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_mongodb"></a> [mongodb](#module\_mongodb) | terraform-module/release/helm | 2.7.0 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_architecture"></a> [architecture](#input\_architecture) | architecture can be replicaset or standalone | `string` | `"replicaset"` | no |
| <a name="input_existing_secret"></a> [existing\_secret](#input\_existing\_secret) | Existing secret with MongoDB(®) credentials (keys: mongodb-password, mongodb-root-password, mongodb-replica-set-key) | `string` | `""` | no |
| <a name="input_name"></a> [name](#input\_name) | mongodb helm release name | `string` | `"mongodb"` | no |
| <a name="input_pvcsize"></a> [pvcsize](#input\_pvcsize) | persistence volume size | `string` | `"8Gi"` | no |
| <a name="input_replicaset_key"></a> [replicaset\_key](#input\_replicaset\_key) | Key used for authentication in the replicaset (only when architecture=replicaset) | `string` | `""` | no |
| <a name="input_resources_limits"></a> [resources\_limits](#input\_resources\_limits) | The resources limits for MongoDB containers | `any` | <pre>{<br/>  "cpu": "500m",<br/>  "memory": "128Mi"<br/>}</pre> | no |
| <a name="input_resources_requests"></a> [resources\_requests](#input\_resources\_requests) | The resources resources for MongoDB containers | `any` | <pre>{<br/>  "cpu": "250m",<br/>  "memory": "64Mi"<br/>}</pre> | no |
| <a name="input_root_password"></a> [root\_password](#input\_root\_password) | root user password | `string` | `"root"` | no |
| <a name="input_service_type"></a> [service\_type](#input\_service\_type) | Service Type | `string` | `"NodePort"` | no |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
