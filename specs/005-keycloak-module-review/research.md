# Research Notes: Keycloak module production readiness

**Created**: 2026-05-05  
**Feature**: `specs/005-keycloak-module-review/spec.md`

## Decisions

### Public URL / redirect-loop prevention

- **Decision**: Ensure Keycloak treats the public endpoint as HTTPS when TLS terminates at the ingress/LB.
- **Rationale**: Prevent HTTP↔HTTPS redirect loops and ensure discovery documents and issued URLs reflect the real public base URL.
- **References**:
  - https://www.keycloak.org/server/hostname
  - https://www.keycloak.org/server/reverseproxy

### Reverse proxy headers

- **Decision**: Default to `proxy_mode = xforwarded` for ALB-like environments where `X-Forwarded-*` headers are authoritative.
- **Rationale**: Keycloak must trust proxy headers to determine scheme/origin correctly in common Kubernetes + ingress patterns.
- **References**:
  - https://www.keycloak.org/server/reverseproxy

### Clustering and cache discovery

- **Decision**: Use the chart default cache stack (`cache.stack = default`) which configures Infinispan with JDBC_PING (Keycloak 26+ default).
- **Rationale**: JDBC_PING reduces network complexity in Kubernetes and is a supported default for multi-replica setups.
- **References**:
  - https://www.keycloak.org/server/caching

### Metrics and Prometheus integration

- **Decision**: Enable metrics and health by default at the module level; keep ServiceMonitor optional/off by default.
- **Rationale**: Metrics/health are common production requirements; ServiceMonitor requires CRDs and cannot be assumed in all clusters.
- **References**:
  - https://www.keycloak.org/observability/configuration-metrics
  - https://www.keycloak.org/observability/event-metrics

### User event metrics

- **Decision**: Support enabling user event metrics to observe login failures and token flows.
- **Rationale**: Operators can derive success/failure rates without parsing logs; tags can be tuned to avoid excessive cardinality.
- **References**:
  - https://www.keycloak.org/observability/event-metrics

## Alternatives considered

- Always require full `hostname_public_url` from consumers instead of deriving HTTPS defaults.
  - Rejected: derivation improves safety for common case while still allowing explicit override.
