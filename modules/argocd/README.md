# argocd

This module deploys Argo CD through the `argoproj/argo-cd` Helm chart as an
opinionated Terraform wrapper for the common deployment path: Argo CD on an
existing Kubernetes cluster, exposed via a consumer-managed **AWS ALB Ingress**.

The interface is intentionally narrow:

- no generic Helm values pass-through (use `extra_configs` as an escape hatch)
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

## Advanced configuration (escape hatch)

If you need an upstream chart option that is not part of this wrapper's inputs, you can use `extra_configs`:

```terraform
module "argocd" {
  source = "dasmeta/shared/any//modules/argocd"

  hostname = "argocd.example.com"

  ingress = {
    enabled = true
  }

  use_existing_admin_secret = true

  extra_configs = {
    # Example only: pass any supported argo-cd chart values here.
    # server = { service = { type = "ClusterIP" } }
  }
}
```

## Notifications

Use `notifications` for the supported notification interface. It defaults to
`null`: omitting it adds no Helm values and preserves existing chart behavior,
including the chart's enabled notifications controller. Setting `notifications = {}`
also preserves chart defaults. Only explicitly supplied, non-null attributes are emitted.

```terraform
module "argocd" {
  source = "dasmeta/shared/any//modules/argocd"

  hostname                  = "argocd.example.com"
  use_existing_admin_secret = true

  notifications = {
    enabled    = true
    argocd_url = "https://argocd.example.com"
    context    = { environment = "dev" }
    secret = {
      create = false
      name   = "argocd-notifications-secret"
    }
    notifiers = {
      "service.slack" = yamlencode({ token = "$slack-token" })
    }
    # Add templates, triggers, and subscriptions for your applications.
  }
}
```

| Input attribute | Helm notification value | Format |
|-----------------|-------------------------|--------|
| `enabled` | `enabled` | Boolean; omission preserves the chart default |
| `argocd_url` | `argocdUrl` | Public Argo CD URL used by message links |
| `context` | `context` | Map of strings, e.g. an explicit environment |
| `secret` | `secret` | Optional `create`, `name`, and `items` attributes |
| `notifiers` | `notifiers` | Map of `service.<name>` to YAML strings |
| `templates` | `templates` | Map of `template.<name>` to YAML strings |
| `triggers` | `triggers` | Map of `trigger.<name>` to YAML strings |
| `subscriptions` | `subscriptions` | List of objects with `recipients`, `triggers`, and optional `selector` |

Use `yamlencode` for notifier/template/trigger definitions or supply existing YAML
strings. This interface targets [chart 9.5.2](https://github.com/argoproj/argo-helm/blob/argo-cd-9.5.2/charts/argo-cd/values.yaml)
and Argo CD v3.3.7. The [Terraform example](examples/notifications) configures Slack
and native [Teams Workflows](https://argo-cd.readthedocs.io/en/release-3.3/operator-manual/notifications/services/teams-workflows/),
with four deployment/health events and application label selection. These are example
policies; the module does not install default triggers or subscribe applications.
Teams Workflows requires an Argo CD version that supports `service.teams-workflows`;
the example does not use legacy Office 365 Connectors.

### Credentials

For externally managed credentials, use `secret.create = false`, set `secret.name`,
and provision the Secret in the release namespace before deploying Argo CD.
Notifier definitions reference Secret keys using strings such as `$slack-token`.
The notifications Secret is separate from the admin `argocd-secret`.
When migrating an existing Helm-managed notification Secret to external
management, use a distinct external Secret name: Helm can delete its old Secret
when `create` changes to `false`.

For Helm-managed credentials, set `secret.create = true` and supply `secret.items`
through sensitive consumer variables. Keep actual tokens and webhook URLs in
`secret.items`, not inline in context, notifiers, templates, or triggers. Item
names support letters, digits, hyphens, and underscores. Dots and other Helm path
syntax are rejected because Helm provider v2 cannot reliably redact those paths
from release metadata. Existing externally managed Secret keys are not subject
to this module validation.

The grouped input is sensitive. Native Secret items also use Helm `set_sensitive`
to redact their paths from provider metadata and normal output. Those sensitive
settings use the final `extra_configs` override value, including null removal.
Legacy credentials supplied only via `extra_configs` retain their existing
handling; migrate them to `notifications.secret.items` or an external Secret.
Sensitivity hides normal CLI display; credentials still reside in Terraform
state and Helm release storage. No credential outputs are added.

### Override precedence and migration

Helm receives module defaults, native notification values, and `extra_configs`
in that order. Maps merge recursively according to Helm rules; later scalar and
list values replace earlier values. `extra_configs.notifications` remains the
final override, including when both interfaces are supplied. Avoid keeping an
old subscription list in `extra_configs` after migrating, because it overrides
the native list.

```terraform
# Before: inside the module block
extra_configs = {
  notifications = {
    argocdUrl = "https://argocd.example.com"
    secret    = { create = false, name = "argocd-notifications-secret" }
    notifiers = { "service.slack" = "token: $slack-token" }
  }
}

# After: replace that notifications subtree with this native input.
# Preserve any unrelated extra_configs entries.
notifications = {
  argocd_url = "https://argocd.example.com"
  secret    = { create = false, name = "argocd-notifications-secret" }
  notifiers = { "service.slack" = "token: $slack-token" }
}
```

Consumers on module version 1.9.0 must upgrade to a release containing this input
before using it. This additive feature is recommended for the next **minor**
release through the repository's normal release process. It changes no chart or
provider version, existing input defaults, or resource addresses; existing
`extra_configs.notifications` configurations continue working without migration.

See the [Terraform example](examples/notifications/README.md) for both destinations,
the four event definitions, and existing Secret references.

<!-- BEGIN_TF_DOCS -->
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
| <a name="input_autoscaling"></a> [autoscaling](#input\_autoscaling) | Argo CD server HPA settings (maps to server.autoscaling in the Helm chart). When enabled, server.replicas is typically ignored by the chart. | <pre>object({<br/>    enabled                              = optional(bool, false)<br/>    min_replicas                         = optional(number, 1)<br/>    max_replicas                         = optional(number, 5)<br/>    target_cpu_utilization_percentage    = optional(number, 50)<br/>    target_memory_utilization_percentage = optional(number, 50)<br/>    behavior                             = optional(any, {})<br/>    metrics                              = optional(any, [])<br/>  })</pre> | `{}` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | The version of the argoproj/argo-cd Helm chart to deploy. | `string` | `"9.5.2"` | no |
| <a name="input_cleanup_on_fail"></a> [cleanup\_on\_fail](#input\_cleanup\_on\_fail) | Allow deletion of new resources created in this upgrade when upgrade fails (helm\_release.cleanup\_on\_fail). | `bool` | `true` | no |
| <a name="input_create_namespace"></a> [create\_namespace](#input\_create\_namespace) | When true, allow Helm to create the target namespace. | `bool` | `false` | no |
| <a name="input_extra_configs"></a> [extra\_configs](#input\_extra\_configs) | Extra Helm values to pass for advanced configuration not covered by this module. Merged on top of module defaults. | `any` | `{}` | no |
| <a name="input_helm_timeout"></a> [helm\_timeout](#input\_helm\_timeout) | Seconds Helm waits for the release when wait is true. | `number` | `900` | no |
| <a name="input_hostname"></a> [hostname](#input\_hostname) | The Argo CD server hostname used when ingress is enabled. | `string` | `null` | no |
| <a name="input_ingress"></a> [ingress](#input\_ingress) | Ingress configuration for the consumer-managed AWS ALB ingress path. | <pre>object({<br/>    enabled            = optional(bool, true)<br/>    controller         = optional(string, "aws")<br/>    ingress_class_name = optional(string, "alb")<br/>    annotations        = optional(map(string), {})<br/>    path               = optional(string, "/")<br/>    path_type          = optional(string, "Prefix")<br/>    tls_secret_name    = optional(string, null)<br/>  })</pre> | `{}` | no |
| <a name="input_name"></a> [name](#input\_name) | The name of the Helm release. | `string` | `"argocd"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | The Kubernetes namespace where Argo CD is deployed. | `string` | `"argocd"` | no |
| <a name="input_notifications"></a> [notifications](#input\_notifications) | Native Argo CD notifications settings. Omitted attributes preserve chart defaults; notifiers, templates, and triggers contain YAML strings. extra\_configs takes precedence. Credentials belong in secret.items or an externally managed Secret. | <pre>object({<br/>    enabled    = optional(bool)<br/>    argocd_url = optional(string)<br/>    context    = optional(map(string))<br/>    secret = optional(object({<br/>      create = optional(bool)<br/>      name   = optional(string)<br/>      items  = optional(map(string))<br/>    }))<br/>    notifiers = optional(map(string))<br/>    templates = optional(map(string))<br/>    triggers  = optional(map(string))<br/>    subscriptions = optional(list(object({<br/>      recipients = list(string)<br/>      triggers   = list(string)<br/>      selector   = optional(string)<br/>    })))<br/>  })</pre> | `null` | no |
| <a name="input_replicas"></a> [replicas](#input\_replicas) | The number of Argo CD server replicas. | `number` | `2` | no |
| <a name="input_resources"></a> [resources](#input\_resources) | Resource requests/limits for the Argo CD server workload. | <pre>object({<br/>    requests = optional(map(string), { cpu = "100m", memory = "256Mi" })<br/>    limits   = optional(map(string), { cpu = "500m", memory = "512Mi" })<br/>  })</pre> | `{}` | no |
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
| <a name="input_autoscaling"></a> [autoscaling](#input\_autoscaling) | Argo CD server HPA settings (maps to server.autoscaling in the Helm chart). When enabled, server.replicas is typically ignored by the chart. | <pre>object({<br/>    enabled                              = optional(bool, false)<br/>    min_replicas                         = optional(number, 1)<br/>    max_replicas                         = optional(number, 5)<br/>    target_cpu_utilization_percentage    = optional(number, 50)<br/>    target_memory_utilization_percentage = optional(number, 50)<br/>    behavior                             = optional(any, {})<br/>    metrics                              = optional(any, [])<br/>  })</pre> | `{}` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | The version of the argoproj/argo-cd Helm chart to deploy. | `string` | `"9.5.2"` | no |
| <a name="input_cleanup_on_fail"></a> [cleanup\_on\_fail](#input\_cleanup\_on\_fail) | Allow deletion of new resources created in this upgrade when upgrade fails (helm\_release.cleanup\_on\_fail). | `bool` | `true` | no |
| <a name="input_create_namespace"></a> [create\_namespace](#input\_create\_namespace) | When true, allow Helm to create the target namespace. | `bool` | `false` | no |
| <a name="input_extra_configs"></a> [extra\_configs](#input\_extra\_configs) | Extra Helm values to pass for advanced configuration not covered by this module. Merged on top of module defaults. | `any` | `{}` | no |
| <a name="input_helm_timeout"></a> [helm\_timeout](#input\_helm\_timeout) | Seconds Helm waits for the release when wait is true. | `number` | `900` | no |
| <a name="input_hostname"></a> [hostname](#input\_hostname) | The Argo CD server hostname used when ingress is enabled. | `string` | `null` | no |
| <a name="input_ingress"></a> [ingress](#input\_ingress) | Ingress configuration for the consumer-managed AWS ALB ingress path. | <pre>object({<br/>    enabled            = optional(bool, true)<br/>    controller         = optional(string, "aws")<br/>    ingress_class_name = optional(string, "alb")<br/>    annotations        = optional(map(string), {})<br/>    path               = optional(string, "/")<br/>    path_type          = optional(string, "Prefix")<br/>    tls_secret_name    = optional(string, null)<br/>  })</pre> | `{}` | no |
| <a name="input_name"></a> [name](#input\_name) | The name of the Helm release. | `string` | `"argocd"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | The Kubernetes namespace where Argo CD is deployed. | `string` | `"argocd"` | no |
| <a name="input_notifications"></a> [notifications](#input\_notifications) | Native Argo CD notifications settings. Omitted attributes preserve chart defaults; notifiers, templates, and triggers contain YAML strings. extra\_configs takes precedence. Credentials belong in secret.items or an externally managed Secret. | <pre>object({<br/>    enabled    = optional(bool)<br/>    argocd_url = optional(string)<br/>    context    = optional(map(string))<br/>    secret = optional(object({<br/>      create = optional(bool)<br/>      name   = optional(string)<br/>      items  = optional(map(string))<br/>    }))<br/>    notifiers = optional(map(string))<br/>    templates = optional(map(string))<br/>    triggers  = optional(map(string))<br/>    subscriptions = optional(list(object({<br/>      recipients = list(string)<br/>      triggers   = list(string)<br/>      selector   = optional(string)<br/>    })))<br/>  })</pre> | `null` | no |
| <a name="input_replicas"></a> [replicas](#input\_replicas) | The number of Argo CD server replicas. | `number` | `2` | no |
| <a name="input_resources"></a> [resources](#input\_resources) | Resource requests/limits for the Argo CD server workload. | <pre>object({<br/>    requests = optional(map(string), { cpu = "100m", memory = "256Mi" })<br/>    limits   = optional(map(string), { cpu = "500m", memory = "512Mi" })<br/>  })</pre> | `{}` | no |
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
