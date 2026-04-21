# Research: Argo CD module review & hardening

**Date**: 2026-04-21  
**Spec**: `spec.md`  
**Plan**: `plan.md`

## Decisions

### Decision: Default `server.insecure=true` when ingress enabled

- **Decision**: Set chart values `configs.params["server.insecure"]="true"` by default for ingress-enabled installs.
- **Rationale**: In the ALB-terminates-TLS pattern, Argo CD should serve HTTP behind the ALB to avoid redirect loops.
- **Alternatives considered**:
  - Make it opt-in only via `extra_configs`
  - Expose a dedicated variable (keeps flexibility but adds interface surface)

### Decision: Namespace creation handled by Helm

- **Decision**: Remove `kubernetes_namespace_*` resources and rely on `helm_release.create_namespace`.
- **Rationale**: Eliminates unnecessary provider coupling and matches sibling module patterns.
- **Alternatives considered**: Keep explicit namespace resource for stricter ordering.

### Decision: Autoscaling interface maps to chart `server.autoscaling`

- **Decision**: Expose a module `autoscaling` object and render it as `server.autoscaling` in Helm values.
- **Rationale**: Upstream chart supports HPA config under `server.autoscaling` (enabled/min/max/targets/behavior/metrics).
- **Alternatives considered**: Require HPA config only through `extra_configs`.

### Decision: `replicas` is always rendered even if autoscaling enabled

- **Decision**: Always render `server.replicas = var.replicas` regardless of autoscaling.
- **Rationale**: Keeps predictable values output and simple mental model; upstream chart will typically ignore replicas when HPA is enabled.
- **Alternatives considered**: Automatically set replicas to `minReplicas` when autoscaling enabled.

### Decision: Escape hatch for additional values via `extra_configs`

- **Decision**: Support `extra_configs` (type `any`) passed as an additional Helm values layer.
- **Rationale**: Keeps wrapper opinionated while enabling advanced chart configuration without forking.
- **Alternatives considered**: Deep-merge module defaults with `cloudposse` module; may be added later if needed.
