# defectdojo

Deploys DefectDojo into Kubernetes with an opinionated Helm-based baseline.
Use this module when you need a shared security-testing installation with a
small input surface and override-friendly chart configuration.

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
| [helm_release.notifications](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.notifications_api_bootstrap](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.notifications_mysql](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.notifications_mysql_bootstrap](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.retention](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.retention_bootstrap](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.this](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_atomic"></a> [atomic](#input\_atomic) | If set, the installation process will be rolled back on failure. | `bool` | `false` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | The DefectDojo Helm chart version to use. | `string` | `"1.9.64"` | no |
| <a name="input_create_namespace"></a> [create\_namespace](#input\_create\_namespace) | Create the namespace if it does not exist. | `bool` | `true` | no |
| <a name="input_custom_configs"></a> [custom\_configs](#input\_custom\_configs) | Additional or override values for the Helm chart. Merged on top of default\_configs. See https://artifacthub.io/packages/helm/defectdojo/defectdojo?modal=values | `any` | `{}` | no |
| <a name="input_default_configs"></a> [default\_configs](#input\_default\_configs) | Default values to pass to the Helm chart. Override specific fields via custom\_configs. | `any` | <pre>{<br/>  "createPostgresqlSecret": true,<br/>  "createSecret": true,<br/>  "createValkeySecret": true<br/>}</pre> | no |
| <a name="input_name"></a> [name](#input\_name) | The name of the Helm release. | `string` | `"defectdojo"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | The Kubernetes namespace to install DefectDojo. | `string` | `"defectdojo"` | no |
| <a name="input_notifications"></a> [notifications](#input\_notifications) | Critical main-branch Trivy notifications, automatically enabled by a configured channel or channels Secret when enabled is omitted; enabled=false explicitly disables and enabled=true requires complete valid configuration. Deliver to any combination of Slack, Teams and Opsgenie, using a dedicated managed MySQL outbox by default. Enabled scheduled jobs persist state and send real notifications. Requires Kubernetes >=1.27 and exactly one channel source: an existing channels\_secret or direct channels values for at least one destination. Slack, Teams and Opsgenie are independent; one Opsgenie integration key authenticates findings and P5 summaries. Direct values use sensitive Helm settings but are stored in Terraform/Helm state; their owned Secret is removed with the worker release independently of retain\_state. API token selection prefers an explicit Secret, otherwise matching-origin retention credentials, otherwise automatic application-account bootstrap. Source and bundled dependencies run in a public Python image; use mysql.create=false for an external MySQL and its existing credentials/CA Secrets. Choose engagement\_ids or explicit all\_engagements=true. Managed provisioning initializes tables. Disabling purges managed PVC/credentials by default and reenabling resends the current Critical backlog; explicitly set retain\_state=true to preserve history. Uninstall uses the last installed hook policy, so apply retention changes while enabled before disabling. External MySQL and shared/caller API/channel Secrets are never purged. Notification-only API token Secrets are removed with their bootstrap without revoking the token. P5 Opsgenie summaries may page depending on integration rules. | <pre>object({<br/>    enabled         = optional(bool)<br/>    retain_state    = optional(bool, false)<br/>    image           = optional(string, "python:3.12-slim@sha256:b18b261e1b4974b4f321451ad5251ded85abb22c2b8b262da527dda1d031ab30")<br/>    api_url         = optional(string, "")<br/>    engagement_ids  = optional(set(number), [])<br/>    all_engagements = optional(bool, false)<br/>    poll_schedule   = optional(string, "0 * * * *")<br/>    digest_schedule = optional(string, "30 13 * * *")<br/>    time_zone       = optional(string, "UTC")<br/>    api_token_secret = optional(object({<br/>      name = optional(string, "")<br/>      key  = optional(string, "api-key")<br/>    }), {})<br/>    mysql = optional(object({<br/>      create        = optional(bool, true)<br/>      image         = optional(string, "mysql:8.4@sha256:a81d043930e51745522bd5c430961cf8286f0a23f0a9a2a6e0108f7ea71b0902")<br/>      storage_size  = optional(string, "8Gi")<br/>      storage_class = optional(string)<br/>      host          = optional(string, "")<br/>      port          = optional(number, 3306)<br/>      database      = optional(string, "defectdojo_notifications")<br/>      tls           = optional(bool, true)<br/>      credentials_secret = optional(object({<br/>        name         = optional(string, "")<br/>        username_key = optional(string, "username")<br/>        password_key = optional(string, "password")<br/>      }), {})<br/>      ca_secret = optional(object({<br/>        name = optional(string, "")<br/>        key  = optional(string, "ca.crt")<br/>      }), {})<br/>    }), {})<br/>    channels = optional(object({<br/>      slack_webhook_url = optional(string, "")<br/>      teams_webhook_url = optional(string, "")<br/>      opsgenie_api_key  = optional(string, "")<br/>    }), {})<br/>    channels_secret = optional(object({<br/>      name         = optional(string, "")<br/>      slack_key    = optional(string, "slack-url")<br/>      teams_key    = optional(string, "teams-url")<br/>      opsgenie_key = optional(string, "opsgenie-key")<br/>    }), {})<br/>    opsgenie_region = optional(string, "us")<br/>    priority        = optional(string, "P2")<br/>  })</pre> | `{}` | no |
| <a name="input_retention"></a> [retention](#input\_retention) | Opt-in cleanup of inactive completed Trivy feature Tests without active findings. Select exactly one of engagement\_ids, exact unique engagement\_names or explicit all\_engagements. Requires Kubernetes >=1.27 and API base URL. Supply an existing API token Secret or enable api\_token\_secret.create to bootstrap one from the chart account. See README for permissions and concurrency limitations. | <pre>object({<br/>    enabled   = optional(bool, false)<br/>    days      = optional(number, 30)<br/>    schedule  = optional(string, "17 2 * * *")<br/>    time_zone = optional(string, "Etc/UTC")<br/>    api_url   = optional(string, "")<br/>    api_token_secret = optional(object({<br/>      create = optional(bool, false)<br/>      name   = optional(string, "")<br/>      key    = optional(string, "api-key")<br/>    }), {})<br/>    engagement_ids         = optional(set(number), [])<br/>    engagement_names       = optional(set(string), [])<br/>    all_engagements        = optional(bool, false)<br/>    protected_branches     = optional(set(string), [])<br/>    protected_environments = optional(set(string), [])<br/>    max_tests_per_run      = optional(number, 10)<br/>  })</pre> | `{}` | no |
| <a name="input_wait"></a> [wait](#input\_wait) | Wait for the release to be deployed successfully. | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_helm_metadata"></a> [helm\_metadata](#output\_helm\_metadata) | DefectDojo Helm release metadata |
| <a name="output_notifications"></a> [notifications](#output\_notifications) | Nonsecret notification release, CronJob, effective API token Secret/key/source, MySQL connection/Secret references and state namespace identifiers; null when disabled. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
