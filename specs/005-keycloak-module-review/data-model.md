# Data Model: Keycloak module production readiness

**Created**: 2026-05-05  
**Feature**: `specs/005-keycloak-module-review/spec.md`

## Entities

### KeycloakReleaseConfig

Represents the consumer configuration for deploying one Keycloak release.

- **Identity**
  - `name`
  - `namespace`
- **Connectivity**
  - `database` (external DB connection and credential source)
- **Public routing**
  - `hostname`
  - `hostname_public_url` (optional)
  - `proxy_mode`
  - `ingress` (optional)
- **Availability**
  - `replicas`
  - `termination_grace_period_seconds` (optional)
  - `pod_disruption_budget` (optional)
- **Escape hatch**
  - `extra_configs`
  - `extra_env`

**Invariants**

- A single Keycloak release must not share the same database with another Keycloak release.
- When TLS terminates at the edge, the public base URL must resolve to HTTPS.

### ObservabilityConfig

Represents module settings that influence operational visibility.

- `metrics_enabled`
- `health_enabled`
- `service_monitor` (optional; must remain disabled by default to avoid CRD dependency)
- `event_metrics`
- `log_level`
- `log_categories`
- `http_metrics_histograms`

### CacheConfig

Represents clustered cache discovery configuration.

- `cache_stack` (default stack uses JDBC_PING via the database)

