# sftpgo

This module deploys SFTPGo through the upstream SFTPGo Helm chart as an
opinionated Terraform wrapper for the common Kubernetes deployment path:
SFTPGo with S3-backed bootstrap user storage, default admin creation,
persistence, and resource controls.

The wrapper focuses on the supported reusable path and avoids exposing the full
Helm chart surface. Use `extra_values` only for chart settings that are outside
the common interface and cannot reasonably wait for a module input.

When `bootstrap_users[*].require_password_change` is true, the bootstrap
container sets SFTPGo's user filter for WebClient/REST API password change at
next login. SFTP protocol logins do not provide an interactive password-change
flow, so verify this behavior through the SFTPGo WebClient.

Bootstrap user `password` and `require_password_change` values are applied only
when the user is created. On later pod starts or Helm upgrades, the bootstrap
container updates the user's S3 filesystem settings while preserving the
existing password and password-change state.

## SFTP TCP exposure

WebUI ingress is HTTP(S)-only. To expose SFTP/SSH, enable the optional
`sftp_service` block so the module creates a separate Kubernetes Service that
publishes only the SFTP port and leaves the chart's shared Service internal.

```terraform
module "sftpgo" {
  source = "dasmeta/shared/any//modules/sftpgo"

  # Required S3, admin, and bootstrap user inputs omitted for brevity.

  sftp_service = {
    enabled = true
    type    = "LoadBalancer"
    port    = 22
    annotations = {
      "service.beta.kubernetes.io/aws-load-balancer-type"   = "nlb"
      "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internal"
    }
  }
}
```

## WebUI session stability

SFTPGo signs WebAdmin and WebClient JWT/CSRF cookies with the HTTPD signing
passphrase. When it is empty, SFTPGo generates a new signing key on every
startup and existing browser sessions become invalid. Configure a stable
sensitive value through `web_session`:

```terraform
module "sftpgo" {
  source = "dasmeta/shared/any//modules/sftpgo"

  # Required deployment inputs omitted for brevity.

  web_session = {
    signing_passphrase = var.sftpgo_web_session_signing_passphrase
    cookie_lifetime     = 720
    token_validation    = 0
  }
}
```

`cookie_lifetime` is measured in minutes and may be set from 1 through 720.
`token_validation = 0` preserves SFTPGo's same-IP validation. Set it to `1`
only when changing client IPs are confirmed to be the reason for session loss;
that removes the IP-match requirement.

## Baseline usage

```terraform
module "sftpgo" {
  source = "dasmeta/shared/any//modules/sftpgo"

  s3_storage = {
    bucket        = "example-sftpgo"
    region        = "eu-central-1"
    access_key    = "example-access-key"
    access_secret = "change-me-s3-secret"
  }

  admin = {
    username = "admin"
    password = "change-me-admin-password"
  }

  bootstrap_users = [
    {
      username   = "demo-user"
      password   = "change-me-user-password"
      key_prefix = "demo-user/"
    }
  ]
}
```

## Secrets

Admin password, WebUI signing passphrase, bootstrap user passwords, and the S3 access secret are accepted
through Terraform variables marked `sensitive`. Terraform will redact these
values in normal CLI output, but they still exist in Terraform state as
sensitive values. Source them from your normal secret workflow and do not commit
real values in `.tfvars` files.

## Supported boundaries

- The module owns SFTPGo Helm deployment configuration only.
- S3-backed bootstrap user storage is the supported storage path for this first
  module version.
- Consumers bring the Kubernetes cluster, Helm provider configuration,
  Kubernetes provider configuration, S3 bucket, and ingress controller when
  ingress is configured through `extra_values`.
- The module creates or updates SFTPGo users through a bootstrap sidecar using
  the SFTPGo API after the service is ready.
- The optional `sftp_service` creates a separate Kubernetes Service for SFTP
  only; it does not expose WebUI or telemetry ports.
- The optional `web_session` configures only the SFTPGo HTTP session fields needed
  for stable browser sessions; it does not expose the full HTTPD chart surface.
- Use neutral names in examples and tests; do not commit customer-specific
  hostnames, paths, or secrets.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | ~> 2.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | ~> 2.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.this](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_service_v1.sftp](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_v1) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin"></a> [admin](#input\_admin) | Default SFTPGo admin bootstrap configuration. The password is supplied through Terraform and stored in state as sensitive. | <pre>object({<br/>    enabled  = optional(bool, true)<br/>    username = optional(string, "admin")<br/>    password = string<br/>  })</pre> | n/a | yes |
| <a name="input_atomic"></a> [atomic](#input\_atomic) | Whether Helm should roll back changes made in case of failed release. | `bool` | `true` | no |
| <a name="input_bootstrap_image"></a> [bootstrap\_image](#input\_bootstrap\_image) | Container image used for the SFTPGo user bootstrap sidecar. | `string` | `"python:3.12-alpine"` | no |
| <a name="input_bootstrap_users"></a> [bootstrap\_users](#input\_bootstrap\_users) | SFTPGo users to create or update during bootstrap. Password and require-password-change settings apply only on creation; existing user credentials are preserved. Passwords are supplied through Terraform and stored in state as sensitive. | <pre>list(object({<br/>    username                = string<br/>    password                = string<br/>    key_prefix              = optional(string)<br/>    home_dir                = optional(string)<br/>    require_password_change = optional(bool, true)<br/>  }))</pre> | n/a | yes |
| <a name="input_chart"></a> [chart](#input\_chart) | The SFTPGo Helm chart name. | `string` | `"sftpgo"` | no |
| <a name="input_chart_repository"></a> [chart\_repository](#input\_chart\_repository) | The SFTPGo Helm chart repository. | `string` | `"oci://ghcr.io/sftpgo/helm-charts"` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | The SFTPGo Helm chart version. | `string` | `"0.45.0"` | no |
| <a name="input_cleanup_on_fail"></a> [cleanup\_on\_fail](#input\_cleanup\_on\_fail) | Whether Helm should delete new resources created during a failed install or upgrade. | `bool` | `true` | no |
| <a name="input_create_namespace"></a> [create\_namespace](#input\_create\_namespace) | Whether Helm should create the namespace. | `bool` | `true` | no |
| <a name="input_extra_values"></a> [extra\_values](#input\_extra\_values) | Additional SFTPGo Helm values merged last. Use sparingly for chart options outside this module's opinionated interface. | `any` | `{}` | no |
| <a name="input_image_pull_secrets"></a> [image\_pull\_secrets](#input\_image\_pull\_secrets) | Image pull secrets passed to the SFTPGo chart. | `list(object({ name = string }))` | `[]` | no |
| <a name="input_name"></a> [name](#input\_name) | The Helm release name. | `string` | `"sftpgo"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | The Kubernetes namespace where SFTPGo is deployed. | `string` | `"sftpgo"` | no |
| <a name="input_persistence"></a> [persistence](#input\_persistence) | SFTPGo persistence configuration. | <pre>object({<br/>    enabled            = optional(bool, true)<br/>    storage_class_name = optional(string)<br/>    access_modes       = optional(list(string), ["ReadWriteOnce"])<br/>    storage            = optional(string, "10Gi")<br/>  })</pre> | `{}` | no |
| <a name="input_replica_count"></a> [replica\_count](#input\_replica\_count) | The number of SFTPGo replicas. | `number` | `1` | no |
| <a name="input_resources"></a> [resources](#input\_resources) | SFTPGo container resource requests and limits. | <pre>object({<br/>    requests = optional(map(string), {<br/>      cpu    = "250m"<br/>      memory = "512Mi"<br/>    })<br/>    limits = optional(map(string), {<br/>      cpu    = "500m"<br/>      memory = "1Gi"<br/>    })<br/>  })</pre> | `{}` | no |
| <a name="input_s3_storage"></a> [s3\_storage](#input\_s3\_storage) | S3 storage configuration used by bootstrap users. access\_secret is supplied through Terraform and stored in state as sensitive. | <pre>object({<br/>    bucket           = string<br/>    region           = string<br/>    access_key       = string<br/>    access_secret    = string<br/>    endpoint         = optional(string)<br/>    force_path_style = optional(bool)<br/>  })</pre> | n/a | yes |
| <a name="input_sftp_service"></a> [sftp\_service](#input\_sftp\_service) | Optional Kubernetes Service for SFTP-only TCP exposure. When enabled, the service selects the SFTPGo pods and exposes only the SFTP port. | <pre>object({<br/>    enabled                     = optional(bool, false)<br/>    type                        = optional(string, "LoadBalancer")<br/>    port                        = optional(number, 22)<br/>    annotations                 = optional(map(string), {})<br/>    load_balancer_class         = optional(string, "service.k8s.aws/nlb")<br/>    load_balancer_source_ranges = optional(list(string), [])<br/>  })</pre> | `{}` | no |
| <a name="input_web_session"></a> [web\_session](#input\_web\_session) | Optional SFTPGo WebAdmin/WebClient session settings. signing\_passphrase must remain stable across pod restarts and is supplied through Terraform as a sensitive value. | <pre>object({<br/>    signing_passphrase = string<br/>    cookie_lifetime     = optional(number, 720)<br/>    token_validation    = optional(number, 0)<br/>  })</pre> | `null` | no |
| <a name="input_strategy"></a> [strategy](#input\_strategy) | SFTPGo deployment strategy values passed to the chart. | <pre>object({<br/>    type = optional(string, "Recreate")<br/>  })</pre> | `{}` | no |
| <a name="input_timeout"></a> [timeout](#input\_timeout) | Seconds Helm waits for the release when wait is true. | `number` | `600` | no |
| <a name="input_wait"></a> [wait](#input\_wait) | Whether Helm should wait until all resources are ready. | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_helm_release_name"></a> [helm\_release\_name](#output\_helm\_release\_name) | The SFTPGo Helm release name. |
| <a name="output_helm_release_namespace"></a> [helm\_release\_namespace](#output\_helm\_release\_namespace) | The SFTPGo Helm release namespace. |
| <a name="output_helm_release_status"></a> [helm\_release\_status](#output\_helm\_release\_status) | The SFTPGo Helm release status. |
| <a name="output_helm_release_version"></a> [helm\_release\_version](#output\_helm\_release\_version) | The deployed SFTPGo Helm chart version. |
| <a name="output_sftp_service_load_balancer_hostname"></a> [sftp\_service\_load\_balancer\_hostname](#output\_sftp\_service\_load\_balancer\_hostname) | The optional SFTP-only Service load balancer hostname, or null until unavailable or disabled. |
| <a name="output_sftp_service_name"></a> [sftp\_service\_name](#output\_sftp\_service\_name) | The optional SFTP-only Kubernetes Service name, or null when disabled. |
| <a name="output_sftp_service_namespace"></a> [sftp\_service\_namespace](#output\_sftp\_service\_namespace) | The optional SFTP-only Kubernetes Service namespace, or null when disabled. |
| <a name="output_sftp_service_port"></a> [sftp\_service\_port](#output\_sftp\_service\_port) | The optional SFTP-only Kubernetes Service port, or null when disabled. |
<!-- END_TF_DOCS -->
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | 2.17.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.38.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.this](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_service_v1.sftp](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_v1) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin"></a> [admin](#input\_admin) | Default SFTPGo admin bootstrap configuration. The password is supplied through Terraform and stored in state as sensitive. | <pre>object({<br/>    enabled  = optional(bool, true)<br/>    username = optional(string, "admin")<br/>    password = string<br/>  })</pre> | n/a | yes |
| <a name="input_atomic"></a> [atomic](#input\_atomic) | Whether Helm should roll back changes made in case of failed release. | `bool` | `true` | no |
| <a name="input_bootstrap_image"></a> [bootstrap\_image](#input\_bootstrap\_image) | Container image used for the SFTPGo user bootstrap sidecar. | `string` | `"python:3.12-alpine"` | no |
| <a name="input_bootstrap_users"></a> [bootstrap\_users](#input\_bootstrap\_users) | SFTPGo users to create or update during bootstrap. Passwords are supplied through Terraform and stored in state as sensitive. | <pre>list(object({<br/>    username                = string<br/>    password                = string<br/>    key_prefix              = optional(string)<br/>    home_dir                = optional(string)<br/>    require_password_change = optional(bool, true)<br/>  }))</pre> | n/a | yes |
| <a name="input_chart"></a> [chart](#input\_chart) | The SFTPGo Helm chart name. | `string` | `"sftpgo"` | no |
| <a name="input_chart_repository"></a> [chart\_repository](#input\_chart\_repository) | The SFTPGo Helm chart repository. | `string` | `"oci://ghcr.io/sftpgo/helm-charts"` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | The SFTPGo Helm chart version. | `string` | `"0.45.0"` | no |
| <a name="input_cleanup_on_fail"></a> [cleanup\_on\_fail](#input\_cleanup\_on\_fail) | Whether Helm should delete new resources created during a failed install or upgrade. | `bool` | `true` | no |
| <a name="input_create_namespace"></a> [create\_namespace](#input\_create\_namespace) | Whether Helm should create the namespace. | `bool` | `true` | no |
| <a name="input_extra_values"></a> [extra\_values](#input\_extra\_values) | Additional SFTPGo Helm values merged last. Use sparingly for chart options outside this module's opinionated interface. | `any` | `{}` | no |
| <a name="input_image_pull_secrets"></a> [image\_pull\_secrets](#input\_image\_pull\_secrets) | Image pull secrets passed to the SFTPGo chart. | `list(object({ name = string }))` | `[]` | no |
| <a name="input_name"></a> [name](#input\_name) | The Helm release name. | `string` | `"sftpgo"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | The Kubernetes namespace where SFTPGo is deployed. | `string` | `"sftpgo"` | no |
| <a name="input_persistence"></a> [persistence](#input\_persistence) | SFTPGo persistence configuration. | <pre>object({<br/>    enabled            = optional(bool, true)<br/>    storage_class_name = optional(string)<br/>    access_modes       = optional(list(string), ["ReadWriteOnce"])<br/>    storage            = optional(string, "10Gi")<br/>  })</pre> | `{}` | no |
| <a name="input_replica_count"></a> [replica\_count](#input\_replica\_count) | The number of SFTPGo replicas. | `number` | `1` | no |
| <a name="input_resources"></a> [resources](#input\_resources) | SFTPGo container resource requests and limits. | <pre>object({<br/>    requests = optional(map(string), {<br/>      cpu    = "250m"<br/>      memory = "512Mi"<br/>    })<br/>    limits = optional(map(string), {<br/>      cpu    = "500m"<br/>      memory = "1Gi"<br/>    })<br/>  })</pre> | `{}` | no |
| <a name="input_s3_storage"></a> [s3\_storage](#input\_s3\_storage) | S3 storage configuration used by bootstrap users. access\_secret is supplied through Terraform and stored in state as sensitive. | <pre>object({<br/>    bucket           = string<br/>    region           = string<br/>    access_key       = string<br/>    access_secret    = string<br/>    endpoint         = optional(string)<br/>    force_path_style = optional(bool)<br/>  })</pre> | n/a | yes |
| <a name="input_sftp_service"></a> [sftp\_service](#input\_sftp\_service) | Optional Kubernetes Service for SFTP-only TCP exposure. When enabled, the service selects the SFTPGo pods and exposes only the SFTP port. | <pre>object({<br/>    enabled                     = optional(bool, false)<br/>    type                        = optional(string, "LoadBalancer")<br/>    port                        = optional(number, 22)<br/>    annotations                 = optional(map(string), {})<br/>    load_balancer_class         = optional(string, "service.k8s.aws/nlb")<br/>    load_balancer_source_ranges = optional(list(string), [])<br/>  })</pre> | `{}` | no |
| <a name="input_strategy"></a> [strategy](#input\_strategy) | SFTPGo deployment strategy values passed to the chart. | <pre>object({<br/>    type = optional(string, "Recreate")<br/>  })</pre> | `{}` | no |
| <a name="input_timeout"></a> [timeout](#input\_timeout) | Seconds Helm waits for the release when wait is true. | `number` | `600` | no |
| <a name="input_wait"></a> [wait](#input\_wait) | Whether Helm should wait until all resources are ready. | `bool` | `true` | no |
| <a name="input_web_session"></a> [web\_session](#input\_web\_session) | Optional SFTPGo WebAdmin/WebClient session settings. signing\_passphrase must remain stable across pod restarts and is supplied through Terraform as a sensitive value. | <pre>object({<br/>    signing_passphrase = string<br/>    cookie_lifetime    = optional(number, 720)<br/>    token_validation   = optional(number, 0)<br/>  })</pre> | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_helm_release_name"></a> [helm\_release\_name](#output\_helm\_release\_name) | The SFTPGo Helm release name. |
| <a name="output_helm_release_namespace"></a> [helm\_release\_namespace](#output\_helm\_release\_namespace) | The SFTPGo Helm release namespace. |
| <a name="output_helm_release_status"></a> [helm\_release\_status](#output\_helm\_release\_status) | The SFTPGo Helm release status. |
| <a name="output_helm_release_version"></a> [helm\_release\_version](#output\_helm\_release\_version) | The deployed SFTPGo Helm chart version. |
| <a name="output_sftp_service_load_balancer_hostname"></a> [sftp\_service\_load\_balancer\_hostname](#output\_sftp\_service\_load\_balancer\_hostname) | The optional SFTP-only Service load balancer hostname, or null until unavailable or disabled. |
| <a name="output_sftp_service_name"></a> [sftp\_service\_name](#output\_sftp\_service\_name) | The optional SFTP-only Kubernetes Service name, or null when disabled. |
| <a name="output_sftp_service_namespace"></a> [sftp\_service\_namespace](#output\_sftp\_service\_namespace) | The optional SFTP-only Kubernetes Service namespace, or null when disabled. |
| <a name="output_sftp_service_port"></a> [sftp\_service\_port](#output\_sftp\_service\_port) | The optional SFTP-only Kubernetes Service port, or null when disabled. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
