# Implementation Plan: Istio and Gateway API Upgrade Configurability

**Branch**: `004-upgrade-istio-gateway-api` | **Date**: 2026-04-23 | **Spec**: `/Users/tmuradyan/projects/dasmeta/terraform-any-shared/specs/004-upgrade-istio-gateway-api/spec.md`
**Input**: Feature specification from `/specs/004-upgrade-istio-gateway-api/spec.md`

## Summary

Implement targeted updates in `modules/istio` and `modules/gateway-api-crds` to (1) support independent image source customization for Istio `base`, `istiod`, and `gateway`; (2) upgrade Istio and Gateway API chart/CRD defaults to currently approved stable releases; and (3) improve CRD upgrade documentation while removing unused `locales.tf` in `gateway-api-crds`. Delivery preserves backwards-compatible defaults, keeps module interfaces opinionated, and updates docs/examples/verification artifacts in the same change set.

## Technical Context

**Terraform/OpenTofu Version**: Terraform `~> 1.3`  
**Providers / Upstream Modules**: `hashicorp/helm (~> 2.0)`, `gavinbunney/kubectl (~> 1.14)`, Helm-chart-managed Istio/Gateway API assets  
**Target Module Path**: `modules/istio`, `modules/gateway-api-crds`  
**Examples / Tests in Scope**: `modules/istio/examples/basic`, `modules/istio/examples/gateway-api-only`, `modules/istio/examples/gateway-api-wildcard-tls-internal-and-external-and-restricted`, `modules/istio/examples/istiod-and-gateway-2-replicas`, `modules/gateway-api-crds/examples/basic`  
**Automation Gates**: `pre-commit` hooks (`terraform_fmt`, `terraform_docs`, file hygiene hooks), repo CI checks for Terraform module changes  
**Target Platform**: Kubernetes clusters where Istio and Gateway API CRDs are installed via Terraform-managed Helm/kubectl resources  
**Constraints**: Preserve current default behavior; no breaking changes without explicit approval; keep interfaces opinionated rather than pass-through  
**Scale/Scope**: Two existing modules plus related README/examples and validation paths in same repository

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] Change stays within one coherent module responsibility and the current repository scope.
- [x] Consumer interface remains opinionated; any interface widening is explicitly documented and approved.
- [x] `README.md`, `examples/`, and verification artifacts updates are listed for every behavior or interface change.
- [x] `versions.tf` or `version.tf` and provider compatibility impacts are reviewed and made explicit when compatibility changes.
- [x] Breaking changes, weakened defaults, or standards conflicts are recorded with approval status before implementation.

Post-design re-check: PASS (no constitution gate violations introduced by planned artifacts).

## Project Structure

### Documentation (this feature)

```text
specs/004-upgrade-istio-gateway-api/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── module-interface.md
└── tasks.md
```

### Source Code (repository root)

```text
modules/istio/
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
├── README.md
└── examples/
    ├── basic/
    ├── gateway-api-only/
    ├── gateway-api-wildcard-tls-internal-and-external-and-restricted/
    └── istiod-and-gateway-2-replicas/

modules/gateway-api-crds/
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
├── README.md
├── files/
│   └── v1.5.0-standard-install.yaml
├── locales.tf (planned removal)
└── examples/basic/

.pre-commit-config.yaml
```

**Structure Decision**: Keep all implementation work localized to existing `modules/istio` and `modules/gateway-api-crds` directories with feature documentation artifacts under `specs/004-upgrade-istio-gateway-api`.

## Phase 0: Research Plan

1. Confirm latest stable Istio chart versions relevant to `base`, `istiod`, and `gateway` and document compatibility constraints.
2. Confirm latest stable Gateway API CRD release and required CRD list naming for `version`/`crdsList` defaults.
3. Define recommended input shape for per-component image overrides that preserves current defaults and validation clarity.
4. Define validation approach to prove no regression in default consumer flow and that override behavior is independently testable.

## Phase 1: Design Outputs

- `research.md`: Decisions and alternatives for version targets, override input model, and validation strategy.
- `data-model.md`: Entities for image override set, version baseline, and CRD version contract with validation/state expectations.
- `contracts/module-interface.md`: Expected module interface behavior for new/updated inputs and compatibility constraints.
- `quickstart.md`: Maintainer execution flow for applying the plan, including checks and update sequence.

Agent context regeneration is intentionally skipped (not explicitly requested).

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Interface widening (new override inputs) | Needed to support independent image sources for three Istio components | Single global image override cannot satisfy component-specific registry policies |
