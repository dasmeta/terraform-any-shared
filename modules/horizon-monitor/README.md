# horizon-monitor

This Terraform module deploys the **Horizon Monitor** service to a Kubernetes cluster using the Helm provider.  
It manages the Helm release, including configuration for image, probes, resources, ingress, and persistent storage.  
The module simplifies deployment by providing defaults suitable for most Horizon environments.

## basic example on how to setup Horizon-monitor

```terraform
module "this" {
  source  = "dasmeta/shared/any//modules/horizon-monitor"
  version = "1.7.0"

  config = {
    APP_NAME = "horizon"
    APP_ENV  = "dev"
    APP_URL  = "https://horizon.example.com"
  }

  ingress = {
    enabled = true
    class   = "nginx"
    hosts = [
      {
        host = "horizon.example.com"
        paths = [
          {
            path     = "/"
            pathType = "Prefix"
          }
        ]
      }
    ]
    annotations = {
      "cert-manager.io/cluster-issuer"                 = "letsencrypt-prod"
      "nginx.ingress.kubernetes.io/force-ssl-redirect" = "true"
    }
    tls = [
      {
        hosts      = ["horizon.example.com"]
        secretName = "horizon-example-com-certificate-cms"
      }
    ]
  }
}
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.23 |

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
| <a name="input_affinity"></a> [affinity](#input\_affinity) | Affinity rules for pod placement | `map(any)` | `{}` | no |
| <a name="input_chart"></a> [chart](#input\_chart) | Path to the base Helm chart | `string` | `"base"` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Version of the base Helm chart | `string` | `"0.3.14"` | no |
| <a name="input_config"></a> [config](#input\_config) | Environment variables | `map(string)` | `{}` | no |
| <a name="input_container_port"></a> [container\_port](#input\_container\_port) | Container port for the application | `number` | `8000` | no |
| <a name="input_create_namespace"></a> [create\_namespace](#input\_create\_namespace) | Whether to create the namespace if it doesn't exist | `bool` | `true` | no |
| <a name="input_env"></a> [env](#input\_env) | Environment name | `string` | `"dev"` | no |
| <a name="input_image"></a> [image](#input\_image) | Container image configuration | <pre>object({<br>    repository = string<br>    tag        = string<br>    pullPolicy = optional(string, "IfNotPresent")<br>  })</pre> | <pre>{<br>  "pullPolicy": "IfNotPresent",<br>  "repository": "dasmeta/horizon-monitor",<br>  "tag": "0.0.2"<br>}</pre> | no |
| <a name="input_ingress"></a> [ingress](#input\_ingress) | Ingress configuration | <pre>object({<br>    enabled     = optional(bool, false)<br>    class       = optional(string, "nginx")<br>    annotations = optional(map(string), {})<br>    hosts = list(object({<br>      host = string<br>      paths = list(object({<br>        path     = string<br>        pathType = optional(string, "Prefix")<br>      }))<br>    }))<br>    tls = optional(list(object({<br>      hosts      = list(string)<br>      secretName = string<br>    })), [])<br>  })</pre> | <pre>{<br>  "enabled": false,<br>  "hosts": []<br>}</pre> | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Additional labels for resources | `map(string)` | `{}` | no |
| <a name="input_liveness_probe"></a> [liveness\_probe](#input\_liveness\_probe) | Liveness probe configuration | <pre>object({<br>    httpGet = object({<br>      path = string<br>      port = string<br>    })<br>    initialDelaySeconds = number<br>    periodSeconds       = number<br>    timeoutSeconds      = number<br>    failureThreshold    = number<br>  })</pre> | <pre>{<br>  "failureThreshold": 3,<br>  "httpGet": {<br>    "path": "/up",<br>    "port": "http"<br>  },<br>  "initialDelaySeconds": 30,<br>  "periodSeconds": 10,<br>  "timeoutSeconds": 5<br>}</pre> | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the application deployment | `string` | `"horizon"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Kubernetes namespace for the deployment | `string` | `"horizon"` | no |
| <a name="input_node_selector"></a> [node\_selector](#input\_node\_selector) | Node selector for pod placement | `map(string)` | `{}` | no |
| <a name="input_product"></a> [product](#input\_product) | Product name | `string` | `"horizon"` | no |
| <a name="input_readiness_probe"></a> [readiness\_probe](#input\_readiness\_probe) | Readiness probe configuration | <pre>object({<br>    httpGet = object({<br>      path = string<br>      port = string<br>    })<br>    initialDelaySeconds = number<br>    periodSeconds       = number<br>    timeoutSeconds      = number<br>    failureThreshold    = number<br>  })</pre> | <pre>{<br>  "failureThreshold": 3,<br>  "httpGet": {<br>    "path": "/up",<br>    "port": "http"<br>  },<br>  "initialDelaySeconds": 30,<br>  "periodSeconds": 10,<br>  "timeoutSeconds": 5<br>}</pre> | no |
| <a name="input_repository"></a> [repository](#input\_repository) | Helm chart repository URL | `string` | `"https://dasmeta.github.io/helm/"` | no |
| <a name="input_resources"></a> [resources](#input\_resources) | Resource limits and requests | <pre>object({<br>    limits = optional(object({<br>      cpu    = optional(string)<br>      memory = optional(string)<br>    }))<br>    requests = optional(object({<br>      cpu    = optional(string)<br>      memory = optional(string)<br>    }))<br>  })</pre> | <pre>{<br>  "limits": {<br>    "cpu": "500m",<br>    "memory": "512Mi"<br>  },<br>  "requests": {<br>    "cpu": "100m",<br>    "memory": "128Mi"<br>  }<br>}</pre> | no |
| <a name="input_service_account"></a> [service\_account](#input\_service\_account) | Service account configuration | <pre>object({<br>    create      = optional(bool, true)<br>    name        = optional(string, "")<br>    annotations = optional(map(string), {})<br>  })</pre> | <pre>{<br>  "create": true<br>}</pre> | no |
| <a name="input_startup_probe"></a> [startup\_probe](#input\_startup\_probe) | Startup probe configuration | <pre>object({<br>    httpGet = object({<br>      path = string<br>      port = string<br>    })<br>    initialDelaySeconds = number<br>    periodSeconds       = number<br>    timeoutSeconds      = number<br>    failureThreshold    = number<br>  })</pre> | <pre>{<br>  "failureThreshold": 3,<br>  "httpGet": {<br>    "path": "/up",<br>    "port": "http"<br>  },<br>  "initialDelaySeconds": 30,<br>  "periodSeconds": 10,<br>  "timeoutSeconds": 5<br>}</pre> | no |
| <a name="input_storage"></a> [storage](#input\_storage) | Persistent storage configuration | <pre>list(object({<br>    persistentVolumeClaimName = string<br>    accessModes               = list(string)<br>    className                 = string<br>    requestedSize             = string<br>    enableDataSource          = optional(bool, false)<br>  }))</pre> | <pre>[<br>  {<br>    "accessModes": [<br>      "ReadWriteMany"<br>    ],<br>    "className": "efs-sc-root",<br>    "enableDataSource": false,<br>    "persistentVolumeClaimName": "storage-horizon",<br>    "requestedSize": "1G"<br>  }<br>]</pre> | no |
| <a name="input_tolerations"></a> [tolerations](#input\_tolerations) | Tolerations for pod placement | <pre>list(object({<br>    key      = string<br>    operator = string<br>    value    = optional(string)<br>    effect   = optional(string)<br>  }))</pre> | `[]` | no |
| <a name="input_volumes"></a> [volumes](#input\_volumes) | Additional volumes configuration | <pre>list(object({<br>    name      = string<br>    mountPath = string<br>    persistentVolumeClaim = optional(object({<br>      claimName = string<br>    }))<br>  }))</pre> | <pre>[<br>  {<br>    "mountPath": "/mnt/sqlite",<br>    "name": "storage-horizon-volume",<br>    "persistentVolumeClaim": {<br>      "claimName": "storage-horizon"<br>    }<br>  }<br>]</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_deployment_name"></a> [deployment\_name](#output\_deployment\_name) | Name of the Kubernetes deployment |
| <a name="output_ingress_hosts"></a> [ingress\_hosts](#output\_ingress\_hosts) | List of ingress hosts |
| <a name="output_release_name"></a> [release\_name](#output\_release\_name) | Name of the Helm release |
| <a name="output_release_namespace"></a> [release\_namespace](#output\_release\_namespace) | Namespace of the Helm release |
| <a name="output_release_status"></a> [release\_status](#output\_release\_status) | Status of the Helm release |
| <a name="output_release_version"></a> [release\_version](#output\_release\_version) | Version of the Helm release |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
