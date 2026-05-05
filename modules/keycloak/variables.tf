variable "name" {
  type        = string
  default     = "keycloak"
  description = "The name of the Helm release."
}

variable "namespace" {
  type        = string
  default     = "keycloak"
  description = "The Kubernetes namespace where Keycloak is deployed."
}

variable "create_namespace" {
  type        = bool
  default     = true
  description = "When true, create the target namespace with the Kubernetes provider before secrets and Helm (required so bootstrap Secrets can be applied)."
}

variable "chart_version" {
  type        = string
  default     = "7.1.9"
  description = "The version of the codecentric/keycloakx Helm chart to deploy."
}

variable "helm_timeout" {
  type        = number
  default     = 900
  description = "Seconds Helm waits for the release when wait is true. Keycloak startup often exceeds the provider default (300s), causing context deadline exceeded with atomic installs."
}

variable "atomic" {
  type        = bool
  default     = true
  description = "Whether to roll back changes made in case of failed release (helm_release.atomic)."
}

variable "cleanup_on_fail" {
  type        = bool
  default     = true
  description = "When true, delete new resources created by a failed install or upgrade (helm_release.cleanup_on_fail)."
}

variable "wait" {
  type        = bool
  default     = true
  description = "Whether to wait for resources to become ready (helm_release.wait)."
}

variable "hostname" {
  type        = string
  description = "Hostname for Ingress rules. When hostname_public_url is null, KC_HOSTNAME becomes https://<hostname> if ingress is enabled and assume_https_public_endpoint is true; otherwise this value is passed through as KC_HOSTNAME."
}

variable "hostname_public_url" {
  type        = string
  default     = null
  description = "Optional full public URL for KC_HOSTNAME (e.g. https://sso.example.com). Overrides assume_https_public_endpoint when set. Use when TLS terminates at the ingress/LB per Keycloak hostname v2 and https://www.keycloak.org/server/hostname ."
}

variable "assume_https_public_endpoint" {
  type        = bool
  default     = true
  description = "When ingress is enabled, hostname_public_url is null, and this is true, set KC_HOSTNAME to https://<hostname> so Keycloak matches the browser URL when TLS terminates at the ALB/ingress (avoids HTTP↔HTTPS redirect loops). Set false if the public entrypoint is plain HTTP."
}

variable "hostname_admin_url" {
  type        = string
  default     = null
  description = "Optional KC_HOSTNAME_ADMIN when the admin console is exposed on a different host than the public frontend (best practice for production)."
}

variable "hostname_backchannel_dynamic" {
  type        = bool
  default     = false
  description = "When true, sets KC_HOSTNAME_BACKCHANNEL_DYNAMIC=true for clients reaching Keycloak on a private URL while the browser uses the public hostname. Requires hostname_public_url to be a full URL when enabled."
}

variable "hostname_strict" {
  type        = bool
  default     = false
  description = "When false, sets KC_HOSTNAME_STRICT=false so Keycloak accepts any Host header (e.g. kubectl port-forward to 127.0.0.1 without redirects to hostname). Prefer hostname_public_url and strict public hostname in production."
}

variable "proxy_mode" {
  type        = string
  default     = "xforwarded"
  description = "Sets keycloakx chart proxy.mode (KC_PROXY_HEADERS). Use xforwarded behind AWS ALB / X-Forwarded-* proxies; see https://www.keycloak.org/server/reverseproxy"
}

variable "replicas" {
  type        = number
  default     = 1
  description = "The number of Keycloak replicas. Use 2+ for HA; chart defaults use JDBC_PING via the database for cache discovery (Keycloak 26+)."
}

variable "cache_stack" {
  type        = string
  default     = "default"
  description = "Helm chart cache.stack. The default value configures distributed caching with the JDBC_PING stack (recommended for Kubernetes). See https://www.keycloak.org/server/caching"
}

variable "termination_grace_period_seconds" {
  type        = number
  default     = null
  description = "Pod termination grace period. Increase for large Infinispan clusters so nodes can rebalance on shutdown (chart default 60 when unset)."
}

variable "pod_disruption_budget" {
  type        = any
  default     = null
  description = "If set, passed to the chart as podDisruptionBudget (e.g. { minAvailable = 1 } or { maxUnavailable = 1 })."
}

variable "admin_username" {
  type        = string
  default     = "admin"
  description = "The initial Keycloak admin username."
}

variable "admin_password" {
  type        = string
  default     = null
  description = "Admin password when the module creates the bootstrap Secret (mutually exclusive with admin_password_secret_name). May be sourced from Terraform Cloud remote state / workspace outputs (same idea as grafana_admin_password); value is sensitive in Terraform state."
  sensitive   = true
}

variable "admin_password_secret_name" {
  type        = string
  default     = null
  description = "Existing Kubernetes Secret name that contains the Keycloak admin password."
}

variable "admin_password_secret_key" {
  type        = string
  default     = "password"
  description = "The key inside the admin password Secret."
}

variable "database" {
  type = object({
    host                 = string
    name                 = string
    username             = string
    vendor               = optional(string, "postgres")
    port                 = optional(number, 5432)
    password             = optional(string)
    password_secret_name = optional(string)
    password_secret_key  = optional(string, "password")
  })
  description = "External PostgreSQL (or supported vendor). Set database.password from remote workspace outputs, OR database.password_secret_name for a pre-existing Secret (e.g. ExternalSecret), not both."
  sensitive   = true
}

variable "ingress" {
  type = object({
    enabled            = optional(bool, true)
    ingress_class_name = optional(string)
    annotations        = optional(map(string), {})
    path               = optional(string, "/")
    path_type          = optional(string, "Prefix")
    tls_secret_name    = optional(string)
  })
  default     = {}
  description = "Ingress configuration for the consumer-managed ingress path."
}

variable "resources" {
  type = object({
    limits   = optional(map(string), {})
    requests = optional(map(string), {})
  })
  default     = {}
  description = "CPU and memory resource requests and limits for Keycloak."
}

variable "pod_labels" {
  type        = map(string)
  default     = {}
  description = "Additional labels applied to the Keycloak pod."
}

variable "pod_annotations" {
  type        = map(string)
  default     = {}
  description = "Additional annotations applied to the Keycloak pod (e.g. extra Prometheus hints if not using ServiceMonitor)."
}

variable "service_annotations" {
  type        = map(string)
  default     = {}
  description = "Annotations on the main HTTP Service (e.g. prometheus.io/* if your Prometheus scrapes Services)."
}

variable "metrics_enabled" {
  type        = bool
  default     = true
  description = "Expose the Prometheus metrics endpoint (/metrics on the management port). The codecentric/keycloakx chart only wires readinessProbe when both metrics and health are enabled."
}

variable "health_enabled" {
  type        = bool
  default     = true
  description = "Expose /health/live, /health/ready, and startup checks. Point load balancers at /health/ready per https://www.keycloak.org/server/configuration-production"
}

variable "service_monitor" {
  type = object({
    enabled            = optional(bool, false)
    interval           = optional(string, "30s")
    scrape_timeout     = optional(string, "10s")
    labels             = optional(map(string), {})
    annotations        = optional(map(string), {})
    namespace          = optional(string, "")
    namespace_selector = optional(map(any), {})
    relabelings        = optional(list(any), [])
    metric_relabelings = optional(list(any), [])
  })
  default     = {}
  description = "Prometheus Operator ServiceMonitor (monitoring.coreos.com/v1). Enable only if the CRD is installed. See chart serviceMonitor values."
}

variable "event_metrics" {
  type = object({
    enabled     = optional(bool, true)
    user_events = optional(string)
    user_tags   = optional(string)
  })
  default     = {}
  description = "User event metrics (KC_EVENT_METRICS_USER_ENABLED) for login/token flows; see https://www.keycloak.org/observability/event-metrics"
}

variable "http_metrics_histograms" {
  type        = bool
  default     = true
  description = "Enable KC_HTTP_METRICS_HISTOGRAMS_ENABLED for request latency histograms (alerting/dashboards)."
}

variable "http_metrics_slos" {
  type        = string
  default     = null
  description = "Optional KC_HTTP_METRICS_SLOS (comma-separated ms buckets) for HTTP latency SLO buckets."
}

variable "cache_metrics_histograms" {
  type        = bool
  default     = false
  description = "Enable KC_CACHE_METRICS_HISTOGRAMS_ENABLED (adds cache latency histograms; higher cardinality)."
}

variable "log_level" {
  type        = string
  default     = "INFO"
  description = "Base KC_LOG_LEVEL (e.g. INFO). Refine with log_categories for troubleshooting."
}

variable "log_categories" {
  type        = map(string)
  default     = {}
  description = "Logger categories merged into KC_LOG_LEVEL (e.g. org.keycloak.events = \"INFO\" for login/admin event lines in logs). Keys are logger names."
}

variable "http_max_queued_requests" {
  type        = number
  default     = null
  description = "Optional KC_HTTP_MAX_QUEUED_REQUESTS for load shedding (https://www.keycloak.org/server/configuration-production)."
}

variable "prefer_ipv4" {
  type        = bool
  default     = false
  description = "When true, append -Djava.net.preferIPv4Stack=true via JAVA_OPTS_APPEND (common on IPv4-only clusters)."
}

variable "java_opts_append" {
  type        = string
  default     = ""
  description = "Additional JVM flags appended to JAVA_OPTS_APPEND (combined with prefer_ipv4 if set)."
}

variable "extra_env" {
  type        = list(any)
  default     = []
  description = "Extra container env entries merged into chart extraEnv (same shape as Kubernetes env vars: name/value or name/valueFrom)."
}

variable "extra_configs" {
  type        = any
  default     = {}
  description = "Additional Helm values merged last (escape hatch for probes, autoscaling, themes, etc.)."
}
