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

### Preserve SFTP client IP

`sftp_service.external_traffic_policy` accepts `Cluster` (the default) or
`Local` for LoadBalancer and NodePort Services. `Local` routes external traffic
only to local pod endpoints and avoids cross-node source NAT. The external load
balancer must also preserve the client IP. For an AWS NLB with instance targets,
verify `preserve_client_ip.enabled=true`; IP targets have different defaults.
ClusterIP Services omit this field, and selecting Local with ClusterIP is rejected.

For one pod in one AZ behind a multi-AZ AWS NLB, use the existing annotations
map to enable cross-zone routing as well as selecting Local:

```hcl
sftp_service = {
  enabled                 = true
  type                    = "LoadBalancer"
  port                    = 22
  external_traffic_policy = "Local"
  annotations = {
    "service.beta.kubernetes.io/aws-load-balancer-scheme"     = "internal"
    "service.beta.kubernetes.io/aws-load-balancer-attributes" = "load_balancing.cross_zone.enabled=true"
  }
}
```

Merge this annotation with existing annotations and attribute entries. Preserve
the existing load balancer scheme, type and target mode when upgrading. Cross-zone
routing allows NLB nodes in other AZs to reach the pod's node; it does not make a
single pod highly available and can add cross-AZ data-transfer costs.
Verify the target group's cross-zone setting inherits the load balancer setting
or is explicitly enabled; an explicit target-group override can disable it.

For an instance-target NLB managed by AWS Load Balancer Controller, Local defaults
to HTTP health checks on the Service's allocated `healthCheckNodePort`. Let
Kubernetes/controller choose that port; do not retain an explicit TCP or
`traffic-port` health-check override. Confirm backend security groups allow the
health checks and only nodes with ready local endpoints become healthy.

Rollout: enable/verify cross-zone routing first, then apply Local and wait for
controller reconciliation and target health convergence. Test SFTP through each
advertised NLB address and confirm a known external client's source IP in SFTPGo
logs. If checks fail, restore Cluster while investigating. The module does not
enable defender rules or choose allowed client CIDRs; configure those separately
after verifying source IPs. `load_balancer_source_ranges` remains available for
consumer-defined network allowlisting. This setting is independent of HTTP
`web_proxy` and does not alter the chart's internal HTTP Service.

See [AWS Load Balancer Controller health checks and annotations](https://kubernetes-sigs.github.io/aws-load-balancer-controller/latest/guide/service/annotations/#health-check).

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

### Trusted reverse proxy

When an ALB or another HTTP proxy forwards requests from different addresses,
configure `web_proxy` so SFTPGo validates sessions against the forwarded client
IP. Keep the stable `web_session` signing passphrase and `token_validation = 0`.

```hcl
web_proxy = {
  proxy_allowed          = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  client_ip_proxy_header = "X-Forwarded-For"
  client_ip_header_depth = 0
}
```

Replace the example CIDRs with the trusted proxy subnets for each environment.
The default header is `X-Forwarded-For` and depth `0` selects the rightmost
address, appropriate for one ALB using its default `append` mode. For multiple
trusted proxies, choose the depth for the actual forwarding chain. Empty trust
lists, invalid CIDRs, universal `/0` ranges and negative/fractional depths are
rejected. Both IPv4 and IPv6 CIDRs are supported.

Restrict application HTTP access using security groups or network policies so
untrusted traffic cannot bypass the proxy. Other workloads in a trusted subnet
must not be able to impersonate it. This input does not create network rules.

`web_proxy` is optional and independent of `web_session`. When enabled, it
configures one HTTP binding on port 8080 with WebAdmin, WebClient and the REST
API enabled, preserving the module's bootstrap API. Consumers with custom HTTP
bindings should manage their complete configuration through `extra_values`.
**`extra_values` is merged at the top level: `extra_values.config` replaces the
entire generated config, including `web_proxy` and `web_session`.** Do not use
it to partially extend these managed settings; `extra_values.ui.ingress` can
still be used alongside them.

After upgrading to a module release containing this input, enable it first in
a test environment. Inspect the rendered/live configuration for the intended
trusted CIDRs, header and unchanged session settings. Re-login once after the
change from proxy IP to client IP, then check that requests through different
proxy nodes retain the same client IP and no IP-mismatch token errors occur.
Also verify WebAdmin, WebClient and bootstrap API access. A changing VPN egress
IP can still invalidate IP-bound sessions even with correct proxy settings.

References: [SFTPGo HTTP configuration](https://docs.sftpgo.com/latest/config-file/)
and [SFTPGo v2.7.1 defaults](https://github.com/drakkan/sftpgo/blob/v2.7.1/sftpgo.json).

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

For the signing passphrase, prefer an existing Kubernetes Secret in the release
namespace, synchronized from your secret manager before deploying SFTPGo:

```hcl
web_session = {
  signing_passphrase_secret_ref = {
    name = "sftpgo-session"
    key  = "signing-passphrase"
  }
  cookie_lifetime  = 720
  token_validation = 0
}
bootstrap_users = []
```

Supply exactly one signing source. With the reference path, the module injects
`SFTPGO_HTTPD__SIGNING_PASSPHRASE` via `secretKeyRef`; it does not read the Secret
or put its value in the ConfigMap/Terraform values. The existing literal path is
unchanged and still stores the value in state and the generated ConfigMap.
Secret creation, synchronization and rotation are consumer responsibilities.
Restart pods to pick up a changed Secret environment value; rotating the signing
key invalidates existing sessions. Remove old literals from source and rotate
previously exposed values; a new reference does not erase Git/state history.

An empty or omitted `bootstrap_users` disables the bootstrap sidecar. It does not
delete, disable or rotate accounts already in SFTPGo. Rotate or disable any weak
existing account through SFTPGo itself. Admin and S3 inputs remain required by
this wrapper and retain their existing Terraform state semantics.

## Planned shutdown and maintenance

```hcl
shutdown = {
  grace_time                       = 300
  termination_grace_period_seconds = 330
}
timeout = 900
```

This opt-in pair sets `SFTPGO_GRACE_TIME` and the pod's termination grace period.
Omission preserves existing behavior. Both values must be integers, application
grace must be positive, and the pod period must be longer. Choose values from
transfer durations and leave Helm enough time for termination, EBS reattachment
and startup. A larger Kubernetes grace period alone does not make SFTPGo drain
transfers. Coordinate NLB target deregistration delay and connection termination
settings with the same window; test a large upload during a dev rollout before
claiming uninterrupted maintenance. A sudden node failure cannot be drained.

The pinned chart already supports optional scheduling and eviction controls via
`extra_values`. Merge the following fields into your existing values if your
maintenance policy requires them:

```hcl
extra_values = {
  podAnnotations = { "karpenter.sh/do-not-disrupt" = "true" }
  nodeSelector   = { "karpenter.sh/nodepool" = "example-protected" }
  pdb = {
    enabled      = true
    minAvailable = 1
  }
}
```

Replace the nodepool name with an existing pool with capacity in the volume's
AZ. Being on a protected node today does not constrain future scheduling.
For one replica, `minAvailable = 1` blocks ordinary eviction/drain until an
operator deliberately adjusts the budget for a maintenance window; it does not
wait for upload completion or protect against node failure. Deployment rollouts
are not blocked by PDBs. `do-not-disrupt` is an additional Karpenter control,
not protection against every forceful disruption. Neither is enabled by default.
Keep `Recreate` for the current SQLite/RWO setup. Two replicas require a separate
external-database/shared-state design and removal of the single-AZ RWO dependency;
existing TCP sessions still cannot migrate between pods after a failure.

`extra_values` retains its existing top-level override contract:
`extra_values.env` replaces generated environment variables (including grace
time); `extra_values.envVars` replaces the generated signing Secret reference;
`extra_values.podTerminationGracePeriodSeconds` overrides the validated period.
Prefer the typed inputs. If overriding these keys, supply their complete intended
contents and verify the rendered Deployment.

References: [SFTPGo serve implementation](https://github.com/drakkan/sftpgo/blob/v2.7.1/internal/cmd/serve.go),
[Kubernetes disruption controls](https://kubernetes.io/docs/concepts/workloads/pods/disruptions/),
[Karpenter disruption controls](https://karpenter.sh/docs/concepts/disruption/).

## Operational issue ownership

| Issue | Module support | Consumer/platform work still required |
| --- | --- | --- |
| 1: WebUI logouts | `web_proxy`, stable `web_session`, Secret reference | Configure trusted proxy CIDRs and HTTP access restrictions in each environment; verify stable VPN egress and browser sessions. |
| 2: SFTP client IP | `sftp_service.external_traffic_policy`, annotations and source ranges | Select Local, configure NLB cross-zone routing/health checks as needed, verify real source IP, then choose client allowlists and defender policy. |
| 3: DNS drift | Service hostname output and NLB-name annotation passthrough already exist | DNS workspace declares the alias and adopts the existing record into its state; preserve lookup/deployment ordering on rebuild. |
| 4: Credentials | Signing Secret reference and optional bootstrap users | Provision/synchronize the Secret, remove committed literals, rotate signing keys and weak active passwords; removing bootstrap configuration is not account deletion. |
| 5: Single pod | Paired shutdown plus chart PDB/annotations/placement through `extra_values` | Bucket owner adds incomplete multipart cleanup; platform owner manages NodePool and NLB drain settings. HA/database/storage migration is a separate design. |

The bucket lifecycle should use `AbortIncompleteMultipartUpload`, for example
after seven days, with a cutoff longer than any legitimate upload. Merge this
rule into the bucket owner's lifecycle configuration; do not create competing
lifecycle resources here. It removes incomplete parts, not completed objects.
See [AWS lifecycle examples](https://docs.aws.amazon.com/AmazonS3/latest/userguide/lifecycle-configuration-examples.html).

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
| <a name="input_bootstrap_users"></a> [bootstrap\_users](#input\_bootstrap\_users) | SFTPGo users to create or update during bootstrap. An empty list disables the bootstrap sidecar without deleting existing users. Passwords are stored in Terraform state as sensitive. | <pre>list(object({<br/>    username                = string<br/>    password                = string<br/>    key_prefix              = optional(string)<br/>    home_dir                = optional(string)<br/>    require_password_change = optional(bool, true)<br/>  }))</pre> | `[]` | no |
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
| <a name="input_sftp_service"></a> [sftp\_service](#input\_sftp\_service) | Optional Kubernetes Service for SFTP-only TCP exposure. When enabled, the service selects the SFTPGo pods and exposes only the SFTP port. | <pre>object({<br/>    enabled                     = optional(bool, false)<br/>    type                        = optional(string, "LoadBalancer")<br/>    port                        = optional(number, 22)<br/>    external_traffic_policy     = optional(string, "Cluster")<br/>    annotations                 = optional(map(string), {})<br/>    load_balancer_class         = optional(string, "service.k8s.aws/nlb")<br/>    load_balancer_source_ranges = optional(list(string), [])<br/>  })</pre> | `{}` | no |
| <a name="input_shutdown"></a> [shutdown](#input\_shutdown) | Optional planned shutdown settings. SFTPGo waits up to grace\_time seconds for transfers; the pod termination period must be longer. Coordinate load balancer draining and Helm timeout separately. | <pre>object({<br/>    grace_time                       = optional(number, 300)<br/>    termination_grace_period_seconds = optional(number, 330)<br/>  })</pre> | `null` | no |
| <a name="input_strategy"></a> [strategy](#input\_strategy) | SFTPGo deployment strategy values passed to the chart. | <pre>object({<br/>    type = optional(string, "Recreate")<br/>  })</pre> | `{}` | no |
| <a name="input_timeout"></a> [timeout](#input\_timeout) | Seconds Helm waits for the release when wait is true. | `number` | `600` | no |
| <a name="input_wait"></a> [wait](#input\_wait) | Whether Helm should wait until all resources are ready. | `bool` | `true` | no |
| <a name="input_web_proxy"></a> [web\_proxy](#input\_web\_proxy) | Optional trusted HTTP proxy configuration for the WebAdmin, WebClient and REST API binding on port 8080. Trust only proxy CIDRs and restrict direct HTTP access to the proxy path. Header depth counts from the right. | <pre>object({<br/>    proxy_allowed          = list(string)<br/>    client_ip_proxy_header = optional(string, "X-Forwarded-For")<br/>    client_ip_header_depth = optional(number, 0)<br/>  })</pre> | `null` | no |
| <a name="input_web_session"></a> [web\_session](#input\_web\_session) | Optional WebAdmin/WebClient session settings. Supply exactly one stable signing\_passphrase or signing\_passphrase\_secret\_ref referencing an existing Secret in the release namespace. Literal values are stored in Terraform state; references do not read the secret. | <pre>object({<br/>    signing_passphrase = optional(string)<br/>    signing_passphrase_secret_ref = optional(object({<br/>      name = string<br/>      key  = string<br/>    }))<br/>    cookie_lifetime  = optional(number, 720)<br/>    token_validation = optional(number, 0)<br/>  })</pre> | `null` | no |

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
| <a name="input_bootstrap_users"></a> [bootstrap\_users](#input\_bootstrap\_users) | SFTPGo users to create or update during bootstrap. An empty list disables the bootstrap sidecar without deleting existing users. Passwords are stored in Terraform state as sensitive. | <pre>list(object({<br/>    username                = string<br/>    password                = string<br/>    key_prefix              = optional(string)<br/>    home_dir                = optional(string)<br/>    require_password_change = optional(bool, true)<br/>  }))</pre> | `[]` | no |
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
| <a name="input_sftp_service"></a> [sftp\_service](#input\_sftp\_service) | Optional Kubernetes Service for SFTP-only TCP exposure. When enabled, the service selects the SFTPGo pods and exposes only the SFTP port. | <pre>object({<br/>    enabled                     = optional(bool, false)<br/>    type                        = optional(string, "LoadBalancer")<br/>    port                        = optional(number, 22)<br/>    external_traffic_policy     = optional(string, "Cluster")<br/>    annotations                 = optional(map(string), {})<br/>    load_balancer_class         = optional(string, "service.k8s.aws/nlb")<br/>    load_balancer_source_ranges = optional(list(string), [])<br/>  })</pre> | `{}` | no |
| <a name="input_shutdown"></a> [shutdown](#input\_shutdown) | Optional planned shutdown settings. SFTPGo waits up to grace\_time seconds for transfers; the pod termination period must be longer. Coordinate load balancer draining and Helm timeout separately. | <pre>object({<br/>    grace_time                       = optional(number, 300)<br/>    termination_grace_period_seconds = optional(number, 330)<br/>  })</pre> | `null` | no |
| <a name="input_strategy"></a> [strategy](#input\_strategy) | SFTPGo deployment strategy values passed to the chart. | <pre>object({<br/>    type = optional(string, "Recreate")<br/>  })</pre> | `{}` | no |
| <a name="input_timeout"></a> [timeout](#input\_timeout) | Seconds Helm waits for the release when wait is true. | `number` | `600` | no |
| <a name="input_wait"></a> [wait](#input\_wait) | Whether Helm should wait until all resources are ready. | `bool` | `true` | no |
| <a name="input_web_proxy"></a> [web\_proxy](#input\_web\_proxy) | Optional trusted HTTP proxy configuration for the WebAdmin, WebClient and REST API binding on port 8080. Trust only proxy CIDRs and restrict direct HTTP access to the proxy path. Header depth counts from the right. | <pre>object({<br/>    proxy_allowed          = list(string)<br/>    client_ip_proxy_header = optional(string, "X-Forwarded-For")<br/>    client_ip_header_depth = optional(number, 0)<br/>  })</pre> | `null` | no |
| <a name="input_web_session"></a> [web\_session](#input\_web\_session) | Optional WebAdmin/WebClient session settings. Supply exactly one stable signing\_passphrase or signing\_passphrase\_secret\_ref referencing an existing Secret in the release namespace. Literal values are stored in Terraform state; references do not read the secret. | <pre>object({<br/>    signing_passphrase = optional(string)<br/>    signing_passphrase_secret_ref = optional(object({<br/>      name = string<br/>      key  = string<br/>    }))<br/>    cookie_lifetime  = optional(number, 720)<br/>    token_validation = optional(number, 0)<br/>  })</pre> | `null` | no |

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
