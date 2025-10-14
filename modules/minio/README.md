## terraform module to install kyverno kubernetes policies management tool, it allows to have predefined policies and also create custom ones

## basic example on how to enable bitnami registry to bitnamilegacy switch automatically
```terraform
module "this" {
  source  = "dasmeta/shared/any//modules/kyverno"
  version = "1.5.0"

  policies = ["bitnami-to-bitnamilegacy"]
}
```
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.8 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.11 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | ~> 2.11 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_custom_default_configs"></a> [custom\_default\_configs](#module\_custom\_default\_configs) | cloudposse/config/yaml//modules/deepmerge | 1.0.2 |

## Resources

| Name | Type |
|------|------|
| [helm_release.minio](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_atomic"></a> [atomic](#input\_atomic) | Whether auto rollback if helm install fails | `bool` | `false` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | The app chart version to use | `string` | `"17.0.21"` | no |
| <a name="input_create_namespace"></a> [create\_namespace](#input\_create\_namespace) | Create namespace if requested | `bool` | `true` | no |
| <a name="input_default_configs"></a> [default\_configs](#input\_default\_configs) | The default values config to pass to helm chart. NOTE: that if you need to change just one field you will need to pass all configs and that field cha changed or you can pass you custom config within var.extra\_configs | `any` | <pre>{<br/>  "accessKey": {<br/>    "password": "sentry"<br/>  },<br/>  "console": {<br/>    "image": {<br/>      "repository": "bitnamilegacy/minio-object-browser"<br/>    }<br/>  },<br/>  "defaultBuckets": "sentry",<br/>  "image": {<br/>    "repository": "bitnamilegacy/minio"<br/>  },<br/>  "persistence": {<br/>    "enabled": true,<br/>    "size": "50Gi"<br/>  },<br/>  "replicas": 3,<br/>  "resources": {<br/>    "limits": {<br/>      "cpu": "600m",<br/>      "memory": "1Gi"<br/>    },<br/>    "requests": {<br/>      "cpu": "300m",<br/>      "memory": "512Mi"<br/>    }<br/>  }<br/>}</pre> | no |
| <a name="input_extra_configs"></a> [extra\_configs](#input\_extra\_configs) | Configs to pass and override helm values.yaml defaults and var.default\_configs if needed more fine control. for more info check https://artifacthub.io/packages/helm/kyverno/kyverno?modal=values | `any` | `{}` | no |
| <a name="input_name"></a> [name](#input\_name) | The name of helm release. | `string` | `"minio"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | The namespace to install app helm. The doc recommends to have kyverno installed in its own namespace so before changing this check docs. | `string` | `"minio"` | no |
| <a name="input_wait"></a> [wait](#input\_wait) | Whether wait to get the workload run successfully | `bool` | `true` | no |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
