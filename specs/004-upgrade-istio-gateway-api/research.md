# Research: Istio and Gateway API Upgrade Configurability

## Decision 1: Use stable upstream releases as module defaults
- **Decision**: Set module defaults to currently stable releases: Istio component chart fallback `1.29.2`, gateway-api chart `0.1.7`, Gateway API CRDs `v1.5.1`.
- **Rationale**: The feature requires freshness while keeping predictable behavior and avoiding pre-release risk.
- **Alternatives considered**:
  - Pin to current versions: rejected because it does not satisfy the requested upgrade.
  - Track release candidates: rejected due to operational instability risk.

## Decision 2: Introduce per-component image override inputs
- **Decision**: Add independent override inputs for Istio `base`, `istiod`, and `gateway` image source configuration while preserving existing defaults.
- **Rationale**: Component-level control is required for private registry and governance use cases without forking the module.
- **Alternatives considered**:
  - One global override: rejected because components may need different sources.
  - Fully pass-through chart values: rejected to preserve opinionated interface boundaries.

## Decision 3: Enforce partial-override validation behavior
- **Decision**: Treat incomplete component override values as invalid and fail clearly during plan/apply.
- **Rationale**: Prevents ambiguous runtime behavior and avoids accidental mixed-source deployments.
- **Alternatives considered**:
  - Silently fill missing fields: rejected because it can mask configuration mistakes.
  - Ignore invalid override blocks: rejected because failures become harder to diagnose.

## Decision 4: Keep CRD upgrade workflow documentation explicit in module README
- **Decision**: Add a documented maintainer workflow for updating CRD YAML and synchronizing `version` and `crdsList`.
- **Rationale**: Reduces tribal knowledge and aligns with requirement for one-pass upgrade guidance.
- **Alternatives considered**:
  - Keep implicit process only in commit history: rejected due to repeatability and onboarding cost.
  - Move process to external docs only: rejected because module README is the primary consumer entry point.

## Decision 5: Remove unused `locales.tf` from gateway-api-crds
- **Decision**: Remove `modules/gateway-api-crds/locales.tf` if no active references remain, and keep behavior intact.
- **Rationale**: Eliminates dead configuration paths and reduces maintenance noise.
- **Alternatives considered**:
  - Leave unused file in place: rejected because it causes confusion and apparent hidden logic.
  - Repurpose file for unrelated locals: rejected because it expands scope without feature value.

## Decision 6: Validation strategy
- **Decision**: Validate via repository pre-commit hooks plus affected module example plan checks.
- **Rationale**: Matches repository governance and directly verifies interface/documentation alignment.
- **Alternatives considered**:
  - Docs-only validation: rejected because behavior and defaults are changing.
  - Broad repo-wide validation only: rejected because targeted feature checks provide better signal.
