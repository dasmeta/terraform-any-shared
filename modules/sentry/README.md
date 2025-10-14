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
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | ~> 2.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_custom_default_configs"></a> [custom\_default\_configs](#module\_custom\_default\_configs) | cloudposse/config/yaml//modules/deepmerge | 1.0.2 |
| <a name="module_minio"></a> [minio](#module\_minio) | ../minio | n/a |

## Resources

| Name | Type |
|------|------|
| [helm_release.this](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_atomic"></a> [atomic](#input\_atomic) | Whether auto rollback if helm install fails | `bool` | `false` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | The app chart version to use | `string` | `"27.4.2"` | no |
| <a name="input_create_namespace"></a> [create\_namespace](#input\_create\_namespace) | Create namespace if requested | `bool` | `true` | no |
| <a name="input_default_configs"></a> [default\_configs](#input\_default\_configs) | The default values config to pass to helm chart. NOTE: that if you need to change just one field you will need to pass all configs and that field cha changed or you can pass you custom config within var.extra\_configs | `any` | <pre>{<br/>  "clickhouse": {<br/>    "enabled": true<br/>  },<br/>  "filestore": {<br/>    "backend": "S3",<br/>    "s3": {<br/>      "bucketName": "Sentry"<br/>    }<br/>  },<br/>  "kafka": {<br/>    "enabled": true<br/>  },<br/>  "postgresql": {<br/>    "auth": {<br/>      "database": "sentry",<br/>      "password": "sentry",<br/>      "username": "sentry"<br/>    },<br/>    "enabled": true<br/>  },<br/>  "redis": {<br/>    "architecture": "standalone",<br/>    "enabled": true,<br/>    "master": {<br/>      "persistence": {<br/>        "enabled": true<br/>      }<br/>    }<br/>  },<br/>  "relay": {<br/>    "enabled": true<br/>  },<br/>  "sentry": {<br/>    "cron": {<br/>      "replicas": 1<br/>    },<br/>    "features": {<br/>      "enableFeedback": true,<br/>      "organizations": {<br/>        "performance-view": true,<br/>        "session-replay": false<br/>      },<br/>      "system": {<br/>        "feedback": true,<br/>        "replays": false<br/>      }<br/>    },<br/>    "image": {<br/>      "repository": "getsentry/sentry",<br/>      "tag": "24.8.0"<br/>    },<br/>    "postProcessForwarder": {<br/>      "replicas": 1<br/>    },<br/>    "resources": {<br/>      "limits": {<br/>        "cpu": "1500m",<br/>        "memory": "1500Mi"<br/>      },<br/>      "requests": {<br/>        "cpu": "1",<br/>        "memory": "1Gi"<br/>      }<br/>    },<br/>    "web": {<br/>      "env": [<br/>        {<br/>          "name": "UWSGI_WORKERS",<br/>          "value": "2"<br/>        }<br/>      ],<br/>      "livenessProbe": {<br/>        "initialDelaySeconds": "180"<br/>      },<br/>      "readinessProbe": {<br/>        "initialDelaySeconds": "120"<br/>      },<br/>      "replicas": 1,<br/>      "resources": {<br/>        "limits": {<br/>          "cpu": "700m",<br/>          "memory": "1700Mi"<br/>        },<br/>        "requests": {<br/>          "cpu": "500m",<br/>          "memory": "1Gi"<br/>        }<br/>      }<br/>    },<br/>    "worker": {<br/>      "replicas": 1<br/>    }<br/>  },<br/>  "snuba": {<br/>    "api": {<br/>      "replicas": 1<br/>    },<br/>    "consumer": {<br/>      "replicas": 1<br/>    },<br/>    "outcomesConsumer": {<br/>      "replicas": 1<br/>    },<br/>    "replacer": {<br/>      "replicas": 1<br/>    },<br/>    "sessionsConsumer": {<br/>      "replicas": 1<br/>    }<br/>  },<br/>  "symbolicator": {<br/>    "enabled": true<br/>  },<br/>  "zookeeper": {<br/>    "enabled": true<br/>  }<br/>}</pre> | no |
| <a name="input_extra_configs"></a> [extra\_configs](#input\_extra\_configs) | Configs to pass and override helm values.yaml defaults and var.default\_configs if needed more fine control. for more info check https://artifacthub.io/packages/helm/kyverno/kyverno?modal=values | `any` | `{}` | no |
| <a name="input_minio_configs"></a> [minio\_configs](#input\_minio\_configs) | Configuration for minio deployment | <pre>object({<br/>    enabled       = optional(bool, true)<br/>    name          = optional(string, "sentry-minio")<br/>    extra_configs = optional(any, {})<br/>    chart_version = optional(string, "17.0.21")<br/>  })</pre> | `{}` | no |
| <a name="input_name"></a> [name](#input\_name) | The name of helm release. | `string` | `"sentry"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | The namespace to install app helm. The doc recommends to have kyverno installed in its own namespace so before changing this check docs. | `string` | `"sentry"` | no |
| <a name="input_wait"></a> [wait](#input\_wait) | Whether wait to get the workload run successfully | `bool` | `true` | no |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
