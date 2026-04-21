# argocd

This module deploys Argo CD through the `argoproj/argo-cd` Helm chart as an
opinionated Terraform wrapper for the common deployment path: Argo CD on an
existing Kubernetes cluster, exposed via a consumer-managed **AWS ALB Ingress**.

The interface is intentionally narrow:

- no generic Helm values pass-through
- no AWS ALB / ACM / Route53 lifecycle ownership
- no SSO/OIDC wiring in this first version

### Admin password modes (pick one)

| Mode | When to use |
|------|-------------|
| **Bcrypt in Terraform** (`admin_password_bcrypt`) | Quick bootstrap. Still ends up in Terraform state (sensitive). |
| **Existing `argocd-secret`** (`use_existing_admin_secret=true`) | Recommended for production when Secrets are managed outside Terraform (e.g. ExternalSecret → AWS Secrets Manager). |

## Baseline usage (ALB Ingress + existing Secret)

```terraform
module "argocd" {
  source = "dasmeta/shared/any//modules/argocd"

  hostname = "argocd.example.com"

  ingress = {
    enabled = true
    annotations = {
      "alb.ingress.kubernetes.io/group.name"  = "my-existing-alb-group"
      "alb.ingress.kubernetes.io/target-type" = "ip"
      "alb.ingress.kubernetes.io/scheme"      = "internal"
      # "alb.ingress.kubernetes.io/certificate-arn" = "arn:aws:acm:region:account:certificate/..."
      # "alb.ingress.kubernetes.io/listen-ports"    = "[{\"HTTPS\":443}]"
      # "alb.ingress.kubernetes.io/ssl-redirect"    = "443"
    }
  }

  use_existing_admin_secret = true
}
```

<!-- BEGIN_TF_DOCS -->
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
| <a name="input_admin_password_bcrypt"></a> [admin\_password\_bcrypt](#input\_admin\_password\_bcrypt) | Bcrypt hash for the Argo CD admin password (not plaintext). Stored in Terraform state as a sensitive value when set. | `string` | `null` | no |
| <a name="input_atomic"></a> [atomic](#input\_atomic) | Whether to roll back changes made in case of failed release (helm\_release.atomic). | `bool` | `true` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | The version of the argoproj/argo-cd Helm chart to deploy. | `string` | `"9.5.2"` | no |
| <a name="input_cleanup_on_fail"></a> [cleanup\_on\_fail](#input\_cleanup\_on\_fail) | Allow deletion of new resources created in this upgrade when upgrade fails (helm\_release.cleanup\_on\_fail). | `bool` | `true` | no |
| <a name="input_create_namespace"></a> [create\_namespace](#input\_create\_namespace) | When true, allow Helm to create the target namespace. | `bool` | `false` | no |
| <a name="input_extra_configs"></a> [extra\_configs](#input\_extra\_configs) | Extra Helm values to pass for advanced configuration not covered by this module. Merged on top of module defaults. | `any` | `{}` | no |
| <a name="input_helm_timeout"></a> [helm\_timeout](#input\_helm\_timeout) | Seconds Helm waits for the release when wait is true. | `number` | `900` | no |
| <a name="input_hostname"></a> [hostname](#input\_hostname) | The Argo CD server hostname used when ingress is enabled. | `string` | `null` | no |
| <a name="input_ingress"></a> [ingress](#input\_ingress) | Ingress configuration for the consumer-managed AWS ALB ingress path. | <pre>object({<br/>    enabled            = optional(bool, true)<br/>    controller         = optional(string, "aws")<br/>    ingress_class_name = optional(string, "alb")<br/>    annotations        = optional(map(string), {})<br/>    path               = optional(string, "/")<br/>    path_type          = optional(string, "Prefix")<br/>    tls_secret_name    = optional(string, null)<br/>  })</pre> | `{}` | no |
| <a name="input_name"></a> [name](#input\_name) | The name of the Helm release. | `string` | `"argocd"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | The Kubernetes namespace where Argo CD is deployed. | `string` | `"argocd"` | no |
| <a name="input_replicas"></a> [replicas](#input\_replicas) | The number of Argo CD server replicas. | `number` | `2` | no |
| <a name="input_resources"></a> [resources](#input\_resources) | Resource requests/limits for the Argo CD server workload. | <pre>object({<br/>    requests = optional(map(string), {<br/>      cpu    = "100m"<br/>      memory = "256Mi"<br/>    })<br/>    limits = optional(map(string), {<br/>      cpu    = "500m"<br/>      memory = "512Mi"<br/>    })<br/>  })</pre> | `{}` | no |
| <a name="input_use_existing_admin_secret"></a> [use\_existing\_admin\_secret](#input\_use\_existing\_admin\_secret) | When true, do not manage admin password material and expect an existing argocd-secret in the target namespace. | `bool` | `false` | no |
| <a name="input_wait"></a> [wait](#input\_wait) | Whether Helm should wait until all resources are in a ready state before marking the release as successful (helm\_release.wait). | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_admin_password_secret_name"></a> [admin\_password\_secret\_name](#output\_admin\_password\_secret\_name) | The Kubernetes Secret name used for Argo CD sensitive settings and (optionally) the admin password. |
| <a name="output_helm_metadata"></a> [helm\_metadata](#output\_helm\_metadata) | Helm release metadata for the deployed Argo CD release. |
| <a name="output_ingress_hostnames"></a> [ingress\_hostnames](#output\_ingress\_hostnames) | Ingress hostnames configured for Argo CD. |
| <a name="output_release_chart_version"></a> [release\_chart\_version](#output\_release\_chart\_version) | Chart version used for the Argo CD Helm release. |
| <a name="output_release_name"></a> [release\_name](#output\_release\_name) | Name of the Argo CD Helm release. |
| <a name="output_release_namespace"></a> [release\_namespace](#output\_release\_namespace) | Namespace of the Argo CD Helm release. |
| <a name="output_release_status"></a> [release\_status](#output\_release\_status) | Status of the Argo CD Helm release. |
<!-- END_TF_DOCS -->
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
| <a name="input_admin_password_bcrypt"></a> [admin\_password\_bcrypt](#input\_admin\_password\_bcrypt) | Bcrypt hash for the Argo CD admin password (not plaintext). Stored in Terraform state as a sensitive value when set. | `string` | `null` | no |
| <a name="input_atomic"></a> [atomic](#input\_atomic) | Whether to roll back changes made in case of failed release (helm\_release.atomic). | `bool` | `true` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | The version of the argoproj/argo-cd Helm chart to deploy. | `string` | `"9.5.2"` | no |
| <a name="input_cleanup_on_fail"></a> [cleanup\_on\_fail](#input\_cleanup\_on\_fail) | Allow deletion of new resources created in this upgrade when upgrade fails (helm\_release.cleanup\_on\_fail). | `bool` | `true` | no |
| <a name="input_create_namespace"></a> [create\_namespace](#input\_create\_namespace) | When true, allow Helm to create the target namespace. | `bool` | `false` | no |
| <a name="input_extra_configs"></a> [extra\_configs](#input\_extra\_configs) | Extra Helm values to pass for advanced configuration not covered by this module. Merged on top of module defaults. | `any` | `{}` | no |
| <a name="input_helm_timeout"></a> [helm\_timeout](#input\_helm\_timeout) | Seconds Helm waits for the release when wait is true. | `number` | `900` | no |
| <a name="input_hostname"></a> [hostname](#input\_hostname) | The Argo CD server hostname used when ingress is enabled. | `string` | `null` | no |
| <a name="input_ingress"></a> [ingress](#input\_ingress) | Ingress configuration for the consumer-managed AWS ALB ingress path. | <pre>object({<br/>    enabled            = optional(bool, true)<br/>    controller         = optional(string, "aws")<br/>    ingress_class_name = optional(string, "alb")<br/>    annotations        = optional(map(string), {})<br/>    path               = optional(string, "/")<br/>    path_type          = optional(string, "Prefix")<br/>    tls_secret_name    = optional(string, null)<br/>  })</pre> | `{}` | no |
| <a name="input_name"></a> [name](#input\_name) | The name of the Helm release. | `string` | `"argocd"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | The Kubernetes namespace where Argo CD is deployed. | `string` | `"argocd"` | no |
| <a name="input_replicas"></a> [replicas](#input\_replicas) | The number of Argo CD server replicas. | `number` | `2` | no |
| <a name="input_resources"></a> [resources](#input\_resources) | Resource requests/limits for the Argo CD server workload. | <pre>object({<br/>    requests = optional(map(string), {<br/>      cpu    = "100m"<br/>      memory = "256Mi"<br/>    })<br/>    limits = optional(map(string), {<br/>      cpu    = "500m"<br/>      memory = "512Mi"<br/>    })<br/>  })</pre> | `{}` | no |
| <a name="input_use_existing_admin_secret"></a> [use\_existing\_admin\_secret](#input\_use\_existing\_admin\_secret) | When true, do not manage admin password material and expect an existing argocd-secret in the target namespace. | `bool` | `false` | no |
| <a name="input_wait"></a> [wait](#input\_wait) | Whether Helm should wait until all resources are in a ready state before marking the release as successful (helm\_release.wait). | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_admin_password_secret_name"></a> [admin\_password\_secret\_name](#output\_admin\_password\_secret\_name) | The Kubernetes Secret name used for Argo CD sensitive settings and (optionally) the admin password. |
| <a name="output_helm_metadata"></a> [helm\_metadata](#output\_helm\_metadata) | Helm release metadata for the deployed Argo CD release. |
| <a name="output_ingress_hostnames"></a> [ingress\_hostnames](#output\_ingress\_hostnames) | Ingress hostnames configured for Argo CD. |
| <a name="output_release_chart_version"></a> [release\_chart\_version](#output\_release\_chart\_version) | Chart version used for the Argo CD Helm release. |
| <a name="output_release_name"></a> [release\_name](#output\_release\_name) | Name of the Argo CD Helm release. |
| <a name="output_release_namespace"></a> [release\_namespace](#output\_release\_namespace) | Namespace of the Argo CD Helm release. |
| <a name="output_release_status"></a> [release\_status](#output\_release\_status) | Status of the Argo CD Helm release. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
