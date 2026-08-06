# keycloak

This module deploys Keycloak through the `codecentric/keycloakx` Helm chart as
an opinionated Terraform wrapper for the common deployment path: Keycloak on an
existing Kubernetes cluster, backed by a consumer-managed external database,
with optional ingress wiring for a consumer-managed ingress controller.

The wrapper focuses on the common external-DB + ingress path and stays opinionated:

- `extra_configs` is supported as an escape hatch for chart options not modeled as variables (probes, autoscaling, themes, and so on).
- no bundled in-module database path
- no ingress controller, DNS, or certificate lifecycle ownership

## Production alignment (Keycloak upstream)

This module follows patterns described in the Keycloak guides:

- [Configuring Keycloak for production](https://www.keycloak.org/server/configuration-production) — health/readiness (`/health/ready` on load balancers), optional `http-max-queued-requests`, clustered caches.
- [Caching / clustering](https://www.keycloak.org/server/caching) — chart `cache.stack` defaults to JDBC_PING (`default`) for multi-replica discovery via the database; run **2+ replicas** for HA.
- [Reverse proxy](https://www.keycloak.org/server/reverseproxy) — `proxy_mode` maps to `KC_PROXY_HEADERS` (`xforwarded` suits AWS ALB when headers are set correctly).
- [Hostname v2](https://www.keycloak.org/server/hostname) — the public URL must reflect **HTTPS** when TLS terminates at the load balancer. Prefer **`hostname_public_url`**, or rely on **`assume_https_public_endpoint`** (default `true` when ingress is enabled) so `KC_HOSTNAME` is `https://<hostname>` and matches the browser. Optional **`hostname_admin_url`** narrows admin console exposure.

### AWS ALB and `ERR_TOO_MANY_REDIRECTS` (same idea as Argo CD)

1. The browser speaks **HTTPS** to the ALB; the ALB forwards **HTTP** to the pod.
2. If Keycloak still behaves as if the client URL were **HTTP**, it can issue a **redirect to HTTPS**.
3. The browser stays on **HTTPS** at the ALB, the ALB keeps sending **HTTP** to Keycloak, and Keycloak redirects again → **loop**.

**What fixes it:** tell Keycloak the real public URL is HTTPS (`KC_HOSTNAME` as `https://your.host` — [edge TLS](https://www.keycloak.org/server/hostname)) and use **`proxy_mode = xforwarded`** so **`X-Forwarded-Proto`** (and related headers) from the ALB are trusted. The chart already sets **`KC_HTTP_ENABLED=true`** for HTTP behind the proxy. With **ingress enabled**, this module defaults **`assume_https_public_endpoint = true`**, so you get `https://<hostname>` for `KC_HOSTNAME` unless you override **`hostname_public_url`**. Use **`assume_https_public_endpoint = false`** only when users reach Keycloak over **plain HTTP** at the edge.

**Observability**

- Metrics: `metrics_enabled` (default `true`) matches `KC_METRICS_ENABLED`; the chart exposes `/metrics` on the management port. **`service_monitor`**: set `enabled = true` when [Prometheus Operator](https://github.com/prometheus-operator/prometheus-operator) `ServiceMonitor` CRDs exist (kube-prometheus-stack).
- User-event metrics (login failures, token-related counters): `event_metrics.enabled` (default `true`) sets `KC_EVENT_METRICS_USER_ENABLED`; see [Event metrics](https://www.keycloak.org/observability/event-metrics). Tune `user_events` / `user_tags` if cardinality is too high.
- HTTP latency histograms: `http_metrics_histograms` (default `true`) enables `KC_HTTP_METRICS_HISTOGRAMS_ENABLED`.
- Logs: `log_level` and `log_categories` set `KC_LOG_LEVEL` (e.g. `org.keycloak.events` for richer login/admin event lines). For durable **admin audit**, also configure realm Admin Events / Event listeners in Keycloak; metrics and logs complement each other.
- Probes: the chart defaults wire liveness/readiness/startup to `/health/*` on the internal port; for long DB migrations, increase startup timing via **`extra_configs`** (override `startupProbe` / `readinessProbe`) per environment.

### Prometheus alert ideas (adapt labels to your scrape config)

| Risk | Starting point |
|------|----------------|
| Pod down / not ready | `kube_pod_status_ready{namespace="keycloak", condition="true"} == 0` or `up{job=~".*keycloak.*"} == 0` |
| Restart loop | `increase(kube_pod_container_status_restarts_total{namespace="keycloak"}[15m]) > 3` |
| DB pool / connectivity stress | `agroal_wait_count` or `agroal_blocking_time_average_millis` rising; log lines from `org.hibernate` / `org.jboss.threads` / JDBC errors |
| High auth failure rate | `sum(rate(keycloak_user_events_total{event="login",error!=""}[5m])) / sum(rate(keycloak_user_events_total{event="login"}[5m])) > 0.05` (adjust `error` label to match your realms) |
| High latency | Histograms from HTTP metrics (e.g. `http_server_requests_seconds_bucket`) — alert on p95/p99 over SLO; optional `http_metrics_slos` for custom buckets |

Use `pod_annotations` / `service_annotations` if you rely on static Prometheus scrape annotations instead of a `ServiceMonitor`.

### Passwords: two supported modes (pick one per credential)

| Mode | When to use |
|------|-------------|
| **Raw in Terraform** (`admin_password`, `database.password`) | Same pattern as other Dasmeta modules that take `${workspace.outputs...}` (e.g. Grafana `grafana_admin_password`). Terraform creates Kubernetes Secrets and Helm references them. |
| **Existing Secret** (`admin_password_secret_name`, `database.password_secret_name`) | You manage Secrets in the cluster (e.g. **ExternalSecret** → AWS Secrets Manager). Terraform only references names; password material is not in this workspace’s inputs. |

You do **not** need a module change to use the Grafana-style approach: pass interpolated secrets as `admin_password` and `database.password`. Do **not** set the `*_secret_name` fields at the same time, and **do not** duplicate the same credential with ExternalSecret unless you intentionally want two sources of truth.

## Baseline usage

```terraform
module "keycloak" {
  source = "dasmeta/shared/any//modules/keycloak"

  hostname       = "keycloak.example.com"
  admin_password = "change-me-admin-password"

  database = {
    host     = "postgresql.example.internal"
    name     = "keycloak"
    username = "keycloak"
    password = "change-me-db-password"
  }
}
```

## Terraform Cloud / remote workspace outputs (Grafana-style)

Link the secrets workspace (e.g. `0-accounts/root/master-secret`) and pass outputs into the module. **Omit** `admin_password_secret_name` / `database.password_secret_name` in this mode.

```terraform
module "keycloak" {
  source = "dasmeta/shared/any//modules/keycloak"

  hostname = "sso.example.com"

  admin_password = data.tfe_outputs.master_secret.values.results.secrets.KEYCLOAK_ADMIN_PASSWORD

  database = {
    host     = "postgresql.example.internal"
    name     = "keycloak"
    username = "keycloak"
    password = data.tfe_outputs.master_secret.values.results.secrets.KEYCLOAK_DB_PASSWORD
  }
}
```

In generated DasMeta YAML this corresponds to `${0-accounts/root/master-secret.secrets.<KEY>}` on `admin_password` and `database.password` (exact structure depends on your wrapper).

## Customization with existing Kubernetes Secrets

Use this when Secrets are created **outside** this Terraform run (ExternalSecret, manual `kubectl`, etc.).

```terraform
module "keycloak" {
  source = "dasmeta/shared/any//modules/keycloak"

  hostname                   = "sso.example.com"
  admin_password_secret_name = "keycloak-admin-password"

  ingress = {
    enabled            = true
    ingress_class_name = "nginx"
    annotations = {
      "cert-manager.io/cluster-issuer" = "letsencrypt"
    }
    tls_secret_name = "keycloak-tls"
  }

  database = {
    host                 = "postgresql.example.internal"
    name                 = "keycloak"
    username             = "keycloak"
    password_secret_name = "keycloak-db-password"
  }
}
```

## Prerequisites

- an existing Kubernetes cluster reachable through the Helm and Kubernetes providers
- a consumer-managed external database supported by the upstream chart
- a consumer-managed ingress controller when ingress is enabled
- for **existing-Secret** mode: consumer-managed Kubernetes Secrets (or ExternalSecrets) in the target namespace
- for **raw password** mode: same linked workspaces as other apps (e.g. master-secret); secrets still end up in Terraform state as **sensitive** attributes

## RBAC note: namespace creation

By default `create_namespace = true` so the module can create the namespace before creating bootstrap Secrets and installing Helm.
If your Terraform identity is not authorized to create namespaces, set **`create_namespace = false`** and pre-create the namespace out-of-band (for example: `kubectl create namespace <namespace>`).

## Supported boundaries

- Password sourcing is explicit: **either** raw `admin_password` / `database.password` **or** `*_secret_name` for each credential, never both for the same slot.
- The module defaults Keycloak to `/` rather than the upstream `/auth` path to
  keep the consumer-facing URL simpler.
- Unmodeled chart options should use `extra_configs` (or `extra_env`) instead of forking the module.

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
| [kubernetes_namespace_v1.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace_v1) | resource |
| [kubernetes_secret_v1.admin_password](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret_v1) | resource |
| [kubernetes_secret_v1.database_password](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret_v1) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin_password"></a> [admin\_password](#input\_admin\_password) | Admin password when the module creates the bootstrap Secret (mutually exclusive with admin\_password\_secret\_name). May be sourced from Terraform Cloud remote state / workspace outputs (same idea as grafana\_admin\_password); value is sensitive in Terraform state. | `string` | `null` | no |
| <a name="input_admin_password_secret_key"></a> [admin\_password\_secret\_key](#input\_admin\_password\_secret\_key) | The key inside the admin password Secret. | `string` | `"password"` | no |
| <a name="input_admin_password_secret_name"></a> [admin\_password\_secret\_name](#input\_admin\_password\_secret\_name) | Existing Kubernetes Secret name that contains the Keycloak admin password. | `string` | `null` | no |
| <a name="input_admin_username"></a> [admin\_username](#input\_admin\_username) | The initial Keycloak admin username. | `string` | `"admin"` | no |
| <a name="input_assume_https_public_endpoint"></a> [assume\_https\_public\_endpoint](#input\_assume\_https\_public\_endpoint) | When ingress is enabled, hostname\_public\_url is null, and this is true, set KC\_HOSTNAME to https://&lt;hostname&gt; so Keycloak matches the browser URL when TLS terminates at the ALB/ingress (avoids HTTP↔HTTPS redirect loops). Set false if the public entrypoint is plain HTTP. | `bool` | `true` | no |
| <a name="input_atomic"></a> [atomic](#input\_atomic) | Whether to roll back changes made in case of failed release (helm\_release.atomic). | `bool` | `true` | no |
| <a name="input_cache_metrics_histograms"></a> [cache\_metrics\_histograms](#input\_cache\_metrics\_histograms) | Enable KC\_CACHE\_METRICS\_HISTOGRAMS\_ENABLED (adds cache latency histograms; higher cardinality). | `bool` | `false` | no |
| <a name="input_cache_stack"></a> [cache\_stack](#input\_cache\_stack) | Helm chart cache.stack. The default value configures distributed caching with the JDBC\_PING stack (recommended for Kubernetes). See https://www.keycloak.org/server/caching | `string` | `"default"` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | The version of the codecentric/keycloakx Helm chart to deploy. | `string` | `"7.1.9"` | no |
| <a name="input_cleanup_on_fail"></a> [cleanup\_on\_fail](#input\_cleanup\_on\_fail) | When true, delete new resources created by a failed install or upgrade (helm\_release.cleanup\_on\_fail). | `bool` | `true` | no |
| <a name="input_create_namespace"></a> [create\_namespace](#input\_create\_namespace) | When true, create the target namespace with the Kubernetes provider before secrets and Helm (required so bootstrap Secrets can be applied). | `bool` | `true` | no |
| <a name="input_database"></a> [database](#input\_database) | External PostgreSQL (or supported vendor). Set database.password from remote workspace outputs, OR database.password\_secret\_name for a pre-existing Secret (e.g. ExternalSecret), not both. | <pre>object({<br/>    host                 = string<br/>    name                 = string<br/>    username             = string<br/>    vendor               = optional(string, "postgres")<br/>    port                 = optional(number, 5432)<br/>    password             = optional(string)<br/>    password_secret_name = optional(string)<br/>    password_secret_key  = optional(string, "password")<br/>  })</pre> | n/a | yes |
| <a name="input_event_metrics"></a> [event\_metrics](#input\_event\_metrics) | User event metrics (KC\_EVENT\_METRICS\_USER\_ENABLED) for login/token flows; see https://www.keycloak.org/observability/event-metrics | <pre>object({<br/>    enabled     = optional(bool, true)<br/>    user_events = optional(string)<br/>    user_tags   = optional(string)<br/>  })</pre> | `{}` | no |
| <a name="input_extra_configs"></a> [extra\_configs](#input\_extra\_configs) | Additional Helm values merged last (escape hatch for probes, autoscaling, themes, etc.). | `any` | `{}` | no |
| <a name="input_extra_env"></a> [extra\_env](#input\_extra\_env) | Extra container env entries merged into chart extraEnv (same shape as Kubernetes env vars: name/value or name/valueFrom). | `list(any)` | `[]` | no |
| <a name="input_health_enabled"></a> [health\_enabled](#input\_health\_enabled) | Expose /health/live, /health/ready, and startup checks. Point load balancers at /health/ready per https://www.keycloak.org/server/configuration-production | `bool` | `true` | no |
| <a name="input_helm_timeout"></a> [helm\_timeout](#input\_helm\_timeout) | Seconds Helm waits for the release when wait is true. Keycloak startup often exceeds the provider default (300s), causing context deadline exceeded with atomic installs. | `number` | `900` | no |
| <a name="input_hostname"></a> [hostname](#input\_hostname) | Hostname for Ingress rules. When hostname\_public\_url is null, KC\_HOSTNAME becomes https://&lt;hostname&gt; if ingress is enabled and assume\_https\_public\_endpoint is true; otherwise this value is passed through as KC\_HOSTNAME. | `string` | n/a | yes |
| <a name="input_hostname_admin_url"></a> [hostname\_admin\_url](#input\_hostname\_admin\_url) | Optional KC\_HOSTNAME\_ADMIN when the admin console is exposed on a different host than the public frontend (best practice for production). | `string` | `null` | no |
| <a name="input_hostname_backchannel_dynamic"></a> [hostname\_backchannel\_dynamic](#input\_hostname\_backchannel\_dynamic) | When true, sets KC\_HOSTNAME\_BACKCHANNEL\_DYNAMIC=true for clients reaching Keycloak on a private URL while the browser uses the public hostname. Requires hostname\_public\_url to be a full URL when enabled. | `bool` | `false` | no |
| <a name="input_hostname_public_url"></a> [hostname\_public\_url](#input\_hostname\_public\_url) | Optional full public URL for KC\_HOSTNAME (e.g. https://sso.example.com). Overrides assume\_https\_public\_endpoint when set. Use when TLS terminates at the ingress/LB per Keycloak hostname v2 and https://www.keycloak.org/server/hostname . | `string` | `null` | no |
| <a name="input_hostname_strict"></a> [hostname\_strict](#input\_hostname\_strict) | When false, sets KC\_HOSTNAME\_STRICT=false so Keycloak accepts any Host header (e.g. kubectl port-forward to 127.0.0.1 without redirects to hostname). Prefer hostname\_public\_url and strict public hostname in production. | `bool` | `false` | no |
| <a name="input_http_max_queued_requests"></a> [http\_max\_queued\_requests](#input\_http\_max\_queued\_requests) | Optional KC\_HTTP\_MAX\_QUEUED\_REQUESTS for load shedding (https://www.keycloak.org/server/configuration-production). | `number` | `null` | no |
| <a name="input_http_metrics_histograms"></a> [http\_metrics\_histograms](#input\_http\_metrics\_histograms) | Enable KC\_HTTP\_METRICS\_HISTOGRAMS\_ENABLED for request latency histograms (alerting/dashboards). | `bool` | `true` | no |
| <a name="input_http_metrics_slos"></a> [http\_metrics\_slos](#input\_http\_metrics\_slos) | Optional KC\_HTTP\_METRICS\_SLOS (comma-separated ms buckets) for HTTP latency SLO buckets. | `string` | `null` | no |
| <a name="input_ingress"></a> [ingress](#input\_ingress) | Ingress configuration for the consumer-managed ingress path. | <pre>object({<br/>    enabled            = optional(bool, true)<br/>    ingress_class_name = optional(string)<br/>    annotations        = optional(map(string), {})<br/>    path               = optional(string, "/")<br/>    path_type          = optional(string, "Prefix")<br/>    tls_secret_name    = optional(string)<br/>  })</pre> | `{}` | no |
| <a name="input_java_opts_append"></a> [java\_opts\_append](#input\_java\_opts\_append) | Additional JVM flags appended to JAVA\_OPTS\_APPEND (combined with prefer\_ipv4 if set). | `string` | `""` | no |
| <a name="input_log_categories"></a> [log\_categories](#input\_log\_categories) | Logger categories merged into KC\_LOG\_LEVEL (e.g. org.keycloak.events = "INFO" for login/admin event lines in logs). Keys are logger names. | `map(string)` | `{}` | no |
| <a name="input_log_level"></a> [log\_level](#input\_log\_level) | Base KC\_LOG\_LEVEL (e.g. INFO). Refine with log\_categories for troubleshooting. | `string` | `"INFO"` | no |
| <a name="input_metrics_enabled"></a> [metrics\_enabled](#input\_metrics\_enabled) | Expose the Prometheus metrics endpoint (/metrics on the management port). The codecentric/keycloakx chart only wires readinessProbe when both metrics and health are enabled. | `bool` | `true` | no |
| <a name="input_name"></a> [name](#input\_name) | The name of the Helm release. | `string` | `"keycloak"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | The Kubernetes namespace where Keycloak is deployed. | `string` | `"keycloak"` | no |
| <a name="input_pod_annotations"></a> [pod\_annotations](#input\_pod\_annotations) | Additional annotations applied to the Keycloak pod (e.g. extra Prometheus hints if not using ServiceMonitor). | `map(string)` | `{}` | no |
| <a name="input_pod_disruption_budget"></a> [pod\_disruption\_budget](#input\_pod\_disruption\_budget) | If set, passed to the chart as podDisruptionBudget (e.g. { minAvailable = 1 } or { maxUnavailable = 1 }). | `any` | `null` | no |
| <a name="input_pod_labels"></a> [pod\_labels](#input\_pod\_labels) | Additional labels applied to the Keycloak pod. | `map(string)` | `{}` | no |
| <a name="input_prefer_ipv4"></a> [prefer\_ipv4](#input\_prefer\_ipv4) | When true, append -Djava.net.preferIPv4Stack=true via JAVA\_OPTS\_APPEND (common on IPv4-only clusters). | `bool` | `false` | no |
| <a name="input_proxy_mode"></a> [proxy\_mode](#input\_proxy\_mode) | Sets keycloakx chart proxy.mode (KC\_PROXY\_HEADERS). Use xforwarded behind AWS ALB / X-Forwarded-* proxies; see https://www.keycloak.org/server/reverseproxy | `string` | `"xforwarded"` | no |
| <a name="input_replicas"></a> [replicas](#input\_replicas) | The number of Keycloak replicas. Use 2+ for HA; chart defaults use JDBC\_PING via the database for cache discovery (Keycloak 26+). | `number` | `1` | no |
| <a name="input_resources"></a> [resources](#input\_resources) | CPU and memory resource requests and limits for Keycloak. | <pre>object({<br/>    limits   = optional(map(string), {})<br/>    requests = optional(map(string), {})<br/>  })</pre> | `{}` | no |
| <a name="input_service_annotations"></a> [service\_annotations](#input\_service\_annotations) | Annotations on the main HTTP Service (e.g. prometheus.io/* if your Prometheus scrapes Services). | `map(string)` | `{}` | no |
| <a name="input_service_monitor"></a> [service\_monitor](#input\_service\_monitor) | Prometheus Operator ServiceMonitor (monitoring.coreos.com/v1). Enable only if the CRD is installed. See chart serviceMonitor values. | <pre>object({<br/>    enabled            = optional(bool, false)<br/>    interval           = optional(string, "30s")<br/>    scrape_timeout     = optional(string, "10s")<br/>    labels             = optional(map(string), {})<br/>    annotations        = optional(map(string), {})<br/>    namespace          = optional(string, "")<br/>    namespace_selector = optional(map(any), {})<br/>    relabelings        = optional(list(any), [])<br/>    metric_relabelings = optional(list(any), [])<br/>  })</pre> | `{}` | no |
| <a name="input_termination_grace_period_seconds"></a> [termination\_grace\_period\_seconds](#input\_termination\_grace\_period\_seconds) | Pod termination grace period. Increase for large Infinispan clusters so nodes can rebalance on shutdown (chart default 60 when unset). | `number` | `null` | no |
| <a name="input_wait"></a> [wait](#input\_wait) | Whether to wait for resources to become ready (helm\_release.wait). | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_admin_password_secret_name"></a> [admin\_password\_secret\_name](#output\_admin\_password\_secret\_name) | The Kubernetes Secret name used for the admin password. |
| <a name="output_database_password_secret_name"></a> [database\_password\_secret\_name](#output\_database\_password\_secret\_name) | The Kubernetes Secret name used for the database password. |
| <a name="output_helm_metadata"></a> [helm\_metadata](#output\_helm\_metadata) | Helm release metadata for the deployed Keycloak release. |
| <a name="output_ingress_hostnames"></a> [ingress\_hostnames](#output\_ingress\_hostnames) | Ingress hostnames configured for Keycloak. |
| <a name="output_release_chart_version"></a> [release\_chart\_version](#output\_release\_chart\_version) | Chart version used for the Keycloak Helm release. |
| <a name="output_release_name"></a> [release\_name](#output\_release\_name) | Name of the Keycloak Helm release. |
| <a name="output_release_namespace"></a> [release\_namespace](#output\_release\_namespace) | Namespace of the Keycloak Helm release. |
| <a name="output_release_status"></a> [release\_status](#output\_release\_status) | Status of the Keycloak Helm release. |
<!-- END_TF_DOCS -->
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_helm"></a> [helm](#provider\_helm) | ~> 2.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | ~> 2.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [helm_release.this](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_namespace_v1.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace_v1) | resource |
| [kubernetes_secret_v1.admin_password](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret_v1) | resource |
| [kubernetes_secret_v1.database_password](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret_v1) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_admin_password"></a> [admin\_password](#input\_admin\_password) | Admin password when the module creates the bootstrap Secret (mutually exclusive with admin\_password\_secret\_name). May be sourced from Terraform Cloud remote state / workspace outputs (same idea as grafana\_admin\_password); value is sensitive in Terraform state. | `string` | `null` | no |
| <a name="input_admin_password_secret_key"></a> [admin\_password\_secret\_key](#input\_admin\_password\_secret\_key) | The key inside the admin password Secret. | `string` | `"password"` | no |
| <a name="input_admin_password_secret_name"></a> [admin\_password\_secret\_name](#input\_admin\_password\_secret\_name) | Existing Kubernetes Secret name that contains the Keycloak admin password. | `string` | `null` | no |
| <a name="input_admin_username"></a> [admin\_username](#input\_admin\_username) | The initial Keycloak admin username. | `string` | `"admin"` | no |
| <a name="input_assume_https_public_endpoint"></a> [assume\_https\_public\_endpoint](#input\_assume\_https\_public\_endpoint) | When ingress is enabled, hostname\_public\_url is null, and this is true, set KC\_HOSTNAME to https://<hostname> so Keycloak matches the browser URL when TLS terminates at the ALB/ingress (avoids HTTP↔HTTPS redirect loops). Set false if the public entrypoint is plain HTTP. | `bool` | `true` | no |
| <a name="input_atomic"></a> [atomic](#input\_atomic) | Whether to roll back changes made in case of failed release (helm\_release.atomic). | `bool` | `true` | no |
| <a name="input_cache_metrics_histograms"></a> [cache\_metrics\_histograms](#input\_cache\_metrics\_histograms) | Enable KC\_CACHE\_METRICS\_HISTOGRAMS\_ENABLED (adds cache latency histograms; higher cardinality). | `bool` | `false` | no |
| <a name="input_cache_stack"></a> [cache\_stack](#input\_cache\_stack) | Helm chart cache.stack. The default value configures distributed caching with the JDBC\_PING stack (recommended for Kubernetes). See https://www.keycloak.org/server/caching | `string` | `"default"` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | The version of the codecentric/keycloakx Helm chart to deploy. | `string` | `"7.1.9"` | no |
| <a name="input_cleanup_on_fail"></a> [cleanup\_on\_fail](#input\_cleanup\_on\_fail) | When true, delete new resources created by a failed install or upgrade (helm\_release.cleanup\_on\_fail). | `bool` | `true` | no |
| <a name="input_create_namespace"></a> [create\_namespace](#input\_create\_namespace) | When true, create the target namespace with the Kubernetes provider before secrets and Helm (required so bootstrap Secrets can be applied). | `bool` | `true` | no |
| <a name="input_database"></a> [database](#input\_database) | External PostgreSQL (or supported vendor). Set database.password from remote workspace outputs, OR database.password\_secret\_name for a pre-existing Secret (e.g. ExternalSecret), not both. | <pre>object({<br/>    host                 = string<br/>    name                 = string<br/>    username             = string<br/>    vendor               = optional(string, "postgres")<br/>    port                 = optional(number, 5432)<br/>    password             = optional(string)<br/>    password_secret_name = optional(string)<br/>    password_secret_key  = optional(string, "password")<br/>  })</pre> | n/a | yes |
| <a name="input_event_metrics"></a> [event\_metrics](#input\_event\_metrics) | User event metrics (KC\_EVENT\_METRICS\_USER\_ENABLED) for login/token flows; see https://www.keycloak.org/observability/event-metrics | <pre>object({<br/>    enabled     = optional(bool, true)<br/>    user_events = optional(string)<br/>    user_tags   = optional(string)<br/>  })</pre> | `{}` | no |
| <a name="input_extra_configs"></a> [extra\_configs](#input\_extra\_configs) | Additional Helm values merged last (escape hatch for probes, autoscaling, themes, etc.). | `any` | `{}` | no |
| <a name="input_extra_env"></a> [extra\_env](#input\_extra\_env) | Extra container env entries merged into chart extraEnv (same shape as Kubernetes env vars: name/value or name/valueFrom). | `list(any)` | `[]` | no |
| <a name="input_health_enabled"></a> [health\_enabled](#input\_health\_enabled) | Expose /health/live, /health/ready, and startup checks. Point load balancers at /health/ready per https://www.keycloak.org/server/configuration-production | `bool` | `true` | no |
| <a name="input_helm_timeout"></a> [helm\_timeout](#input\_helm\_timeout) | Seconds Helm waits for the release when wait is true. Keycloak startup often exceeds the provider default (300s), causing context deadline exceeded with atomic installs. | `number` | `900` | no |
| <a name="input_hostname"></a> [hostname](#input\_hostname) | Hostname for Ingress rules. When hostname\_public\_url is null, KC\_HOSTNAME becomes https://<hostname> if ingress is enabled and assume\_https\_public\_endpoint is true; otherwise this value is passed through as KC\_HOSTNAME. | `string` | n/a | yes |
| <a name="input_hostname_admin_url"></a> [hostname\_admin\_url](#input\_hostname\_admin\_url) | Optional KC\_HOSTNAME\_ADMIN when the admin console is exposed on a different host than the public frontend (best practice for production). | `string` | `null` | no |
| <a name="input_hostname_backchannel_dynamic"></a> [hostname\_backchannel\_dynamic](#input\_hostname\_backchannel\_dynamic) | When true, sets KC\_HOSTNAME\_BACKCHANNEL\_DYNAMIC=true for clients reaching Keycloak on a private URL while the browser uses the public hostname. Requires hostname\_public\_url to be a full URL when enabled. | `bool` | `false` | no |
| <a name="input_hostname_public_url"></a> [hostname\_public\_url](#input\_hostname\_public\_url) | Optional full public URL for KC\_HOSTNAME (e.g. https://sso.example.com). Overrides assume\_https\_public\_endpoint when set. Use when TLS terminates at the ingress/LB per Keycloak hostname v2 and https://www.keycloak.org/server/hostname . | `string` | `null` | no |
| <a name="input_hostname_strict"></a> [hostname\_strict](#input\_hostname\_strict) | When false, sets KC\_HOSTNAME\_STRICT=false so Keycloak accepts any Host header (e.g. kubectl port-forward to 127.0.0.1 without redirects to hostname). Prefer hostname\_public\_url and strict public hostname in production. | `bool` | `false` | no |
| <a name="input_http_max_queued_requests"></a> [http\_max\_queued\_requests](#input\_http\_max\_queued\_requests) | Optional KC\_HTTP\_MAX\_QUEUED\_REQUESTS for load shedding (https://www.keycloak.org/server/configuration-production). | `number` | `null` | no |
| <a name="input_http_metrics_histograms"></a> [http\_metrics\_histograms](#input\_http\_metrics\_histograms) | Enable KC\_HTTP\_METRICS\_HISTOGRAMS\_ENABLED for request latency histograms (alerting/dashboards). | `bool` | `true` | no |
| <a name="input_http_metrics_slos"></a> [http\_metrics\_slos](#input\_http\_metrics\_slos) | Optional KC\_HTTP\_METRICS\_SLOS (comma-separated ms buckets) for HTTP latency SLO buckets. | `string` | `null` | no |
| <a name="input_ingress"></a> [ingress](#input\_ingress) | Ingress configuration for the consumer-managed ingress path. | <pre>object({<br/>    enabled            = optional(bool, true)<br/>    ingress_class_name = optional(string)<br/>    annotations        = optional(map(string), {})<br/>    path               = optional(string, "/")<br/>    path_type          = optional(string, "Prefix")<br/>    tls_secret_name    = optional(string)<br/>  })</pre> | `{}` | no |
| <a name="input_java_opts_append"></a> [java\_opts\_append](#input\_java\_opts\_append) | Additional JVM flags appended to JAVA\_OPTS\_APPEND (combined with prefer\_ipv4 if set). | `string` | `""` | no |
| <a name="input_log_categories"></a> [log\_categories](#input\_log\_categories) | Logger categories merged into KC\_LOG\_LEVEL (e.g. org.keycloak.events = "INFO" for login/admin event lines in logs). Keys are logger names. | `map(string)` | `{}` | no |
| <a name="input_log_level"></a> [log\_level](#input\_log\_level) | Base KC\_LOG\_LEVEL (e.g. INFO). Refine with log\_categories for troubleshooting. | `string` | `"INFO"` | no |
| <a name="input_metrics_enabled"></a> [metrics\_enabled](#input\_metrics\_enabled) | Expose the Prometheus metrics endpoint (/metrics on the management port). The codecentric/keycloakx chart only wires readinessProbe when both metrics and health are enabled. | `bool` | `true` | no |
| <a name="input_name"></a> [name](#input\_name) | The name of the Helm release. | `string` | `"keycloak"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | The Kubernetes namespace where Keycloak is deployed. | `string` | `"keycloak"` | no |
| <a name="input_pod_annotations"></a> [pod\_annotations](#input\_pod\_annotations) | Additional annotations applied to the Keycloak pod (e.g. extra Prometheus hints if not using ServiceMonitor). | `map(string)` | `{}` | no |
| <a name="input_pod_disruption_budget"></a> [pod\_disruption\_budget](#input\_pod\_disruption\_budget) | If set, passed to the chart as podDisruptionBudget (e.g. { minAvailable = 1 } or { maxUnavailable = 1 }). | `any` | `null` | no |
| <a name="input_pod_labels"></a> [pod\_labels](#input\_pod\_labels) | Additional labels applied to the Keycloak pod. | `map(string)` | `{}` | no |
| <a name="input_prefer_ipv4"></a> [prefer\_ipv4](#input\_prefer\_ipv4) | When true, append -Djava.net.preferIPv4Stack=true via JAVA\_OPTS\_APPEND (common on IPv4-only clusters). | `bool` | `false` | no |
| <a name="input_proxy_mode"></a> [proxy\_mode](#input\_proxy\_mode) | Sets keycloakx chart proxy.mode (KC\_PROXY\_HEADERS). Use xforwarded behind AWS ALB / X-Forwarded-* proxies; see https://www.keycloak.org/server/reverseproxy | `string` | `"xforwarded"` | no |
| <a name="input_replicas"></a> [replicas](#input\_replicas) | The number of Keycloak replicas. Use 2+ for HA; chart defaults use JDBC\_PING via the database for cache discovery (Keycloak 26+). | `number` | `1` | no |
| <a name="input_resources"></a> [resources](#input\_resources) | CPU and memory resource requests and limits for Keycloak. | <pre>object({<br/>    limits   = optional(map(string), {})<br/>    requests = optional(map(string), {})<br/>  })</pre> | `{}` | no |
| <a name="input_service_annotations"></a> [service\_annotations](#input\_service\_annotations) | Annotations on the main HTTP Service (e.g. prometheus.io/* if your Prometheus scrapes Services). | `map(string)` | `{}` | no |
| <a name="input_service_monitor"></a> [service\_monitor](#input\_service\_monitor) | Prometheus Operator ServiceMonitor (monitoring.coreos.com/v1). Enable only if the CRD is installed. See chart serviceMonitor values. | <pre>object({<br/>    enabled            = optional(bool, false)<br/>    interval           = optional(string, "30s")<br/>    scrape_timeout     = optional(string, "10s")<br/>    labels             = optional(map(string), {})<br/>    annotations        = optional(map(string), {})<br/>    namespace          = optional(string, "")<br/>    namespace_selector = optional(map(any), {})<br/>    relabelings        = optional(list(any), [])<br/>    metric_relabelings = optional(list(any), [])<br/>  })</pre> | `{}` | no |
| <a name="input_termination_grace_period_seconds"></a> [termination\_grace\_period\_seconds](#input\_termination\_grace\_period\_seconds) | Pod termination grace period. Increase for large Infinispan clusters so nodes can rebalance on shutdown (chart default 60 when unset). | `number` | `null` | no |
| <a name="input_wait"></a> [wait](#input\_wait) | Whether to wait for resources to become ready (helm\_release.wait). | `bool` | `true` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_admin_password_secret_name"></a> [admin\_password\_secret\_name](#output\_admin\_password\_secret\_name) | The Kubernetes Secret name used for the admin password. |
| <a name="output_database_password_secret_name"></a> [database\_password\_secret\_name](#output\_database\_password\_secret\_name) | The Kubernetes Secret name used for the database password. |
| <a name="output_helm_metadata"></a> [helm\_metadata](#output\_helm\_metadata) | Helm release metadata for the deployed Keycloak release. |
| <a name="output_ingress_hostnames"></a> [ingress\_hostnames](#output\_ingress\_hostnames) | Ingress hostnames configured for Keycloak. |
| <a name="output_release_chart_version"></a> [release\_chart\_version](#output\_release\_chart\_version) | Chart version used for the Keycloak Helm release. |
| <a name="output_release_name"></a> [release\_name](#output\_release\_name) | Name of the Keycloak Helm release. |
| <a name="output_release_namespace"></a> [release\_namespace](#output\_release\_namespace) | Namespace of the Keycloak Helm release. |
| <a name="output_release_status"></a> [release\_status](#output\_release\_status) | Status of the Keycloak Helm release. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
