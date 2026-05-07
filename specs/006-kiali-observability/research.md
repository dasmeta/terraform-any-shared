# Research: Kiali Observability For Istio

## Decision 1: Keep Kiali optional by default in Istio module
- **Decision**: `modules/istio` keeps Kiali disabled by default and delegates only when `configs.kiali.enabled = true`.
- **Rationale**: Preserves existing consumer behavior and avoids unexpected resources in current Istio deployments.
- **Alternatives considered**:
  - Enable Kiali by default: rejected due to compatibility risk.
  - Separate mandatory Kiali dependency path: rejected because feature explicitly requires optional delegation.

## Decision 2: Model Kiali as dedicated wrapper module with bounded inputs
- **Decision**: Use `modules/kiali` as the primary abstraction for Kiali operator + Kiali CR configuration, exposing common Prometheus/Grafana knobs and a raw `spec` overlay for advanced fields.
- **Rationale**: Keeps a curated interface for common use-cases while still allowing advanced consumers to extend behavior safely.
- **Alternatives considered**:
  - Full pass-through of entire Kiali CR schema: rejected to preserve opinionated wrapper pattern.
  - Only raw spec input: rejected because common observability fields would become hard to use and document.

## Decision 3: Support Kiali server image override through CR deployment fields
- **Decision**: Map `configs.kiali.image.server.repository/tag` into Kiali CR deployment image fields and ensure operator-side ad-hoc image allowance is enabled when needed.
- **Rationale**: Kiali server image overrides must be effective in real deployments and not silently ignored by operator restrictions.
- **Alternatives considered**:
  - Expose only operator image override: rejected because it does not satisfy Kiali server image customization.
  - Require users to set raw CR `spec` manually: rejected because common-case behavior should stay first-class.

## Decision 4: Include Kiali customization in custom chart/image overrides example
- **Decision**: Extend `modules/istio/examples/custom-chart-and-image-overrides` to also include `configs.kiali` customization.
- **Rationale**: Clarified requirement in spec (FR-009) requires one integrated example for chart/image customization plus Kiali usage.
- **Alternatives considered**:
  - Keep Kiali only in dedicated example: rejected because it does not meet clarified requirement.
  - Create another new example folder: rejected due to unnecessary duplication.

## Decision 5: Validation strategy for module and example changes
- **Decision**: Validate with `terraform fmt`, relevant pre-commit hooks, and targeted example validation/plan commands where provider initialization is available.
- **Rationale**: Matches repository delivery gates and verifies both interface correctness and runnable examples.
- **Alternatives considered**:
  - Documentation-only checks: rejected because behavior and interface are changing.
  - Full-repo validation only: rejected because targeted checks provide faster and clearer feedback for this scoped feature.
