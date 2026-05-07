# Implementation Plan: Kiali Observability For Istio

**Branch**: `006-kiali-observability` | **Date**: 2026-05-07 | **Spec**: `/Users/tmuradyan/projects/dasmeta/terraform-any-shared/specs/006-kiali-observability/spec.md`
**Input**: Feature specification from `/specs/006-kiali-observability/spec.md`

## Summary

Deliver and finalize Kiali observability support through a dedicated `modules/kiali` module and optional delegation from `modules/istio`, including support for Prometheus and Grafana integration, Kiali server image override behavior, and documentation/examples that include both a dedicated Kiali example and Kiali usage inside the `custom-chart-and-image-overrides` Istio example.

## Technical Context

**Terraform/OpenTofu Version**: Terraform `~> 1.3`  
**Providers / Upstream Modules**: `hashicorp/helm (~> 2.0)`, `gavinbunney/kubectl (~> 1.14)`, Kiali operator chart from `https://kiali.org/helm-charts`  
**Target Module Path**: `modules/kiali`, `modules/istio`  
**Examples / Tests in Scope**: `modules/kiali/examples/basic`, `modules/istio/examples/kiali-observability`, `modules/istio/examples/custom-chart-and-image-overrides`  
**Automation Gates**: `terraform fmt`, `pre-commit` (`terraform_fmt`, `terraform_docs`), affected-example `terraform validate` / `terraform plan` where provider initialization is available  
**Target Platform**: Kubernetes clusters with Istio and Gateway API CRDs, where Kiali operator + Kiali CR are managed by Terraform  
**Constraints**: Keep Istio defaults unchanged when Kiali is omitted; preserve opinionated wrapper interface; no breaking changes without explicit approval  
**Scale/Scope**: Existing modules only (`modules/kiali` and `modules/istio`) plus related docs/examples/contracts under the active spec

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] Change stays within one coherent module responsibility and the current repository scope.
- [x] Consumer interface remains opinionated; any interface widening is explicitly documented and approved.
- [x] `README.md`, `examples/`, and `tests/` updates are listed for every behavior or interface change.
- [x] `versions.tf` or `version.tf` and `providers.tf` impacts are reviewed and made explicit when compatibility changes.
- [x] Breaking changes, weakened defaults, or standards conflicts are recorded with approval status before implementation.

Post-design re-check: PASS (planned outputs preserve default compatibility and keep interface additions bounded).

## Project Structure

### Documentation (this feature)

```text
specs/006-kiali-observability/
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
modules/kiali/
├── main.tf
├── locals.tf
├── variables.tf
├── outputs.tf
├── versions.tf
├── README.md
└── examples/basic/

modules/istio/
├── main.tf
├── variables.tf
├── locals.tf
├── outputs.tf
├── versions.tf
├── README.md
└── examples/
    ├── kiali-observability/
    └── custom-chart-and-image-overrides/

.pre-commit-config.yaml
```

**Structure Decision**: Keep implementation inside existing `modules/kiali` and `modules/istio` boundaries, with feature design artifacts under `specs/006-kiali-observability`.

## Phase 0: Research Plan

1. Confirm Kiali operator behaviors required for server image overrides (including ad-hoc image enablement) and map those requirements to wrapper inputs.
2. Confirm wrapper-level defaulting strategy for Istio-to-Kiali delegation that keeps existing Istio consumer behavior unchanged.
3. Define example and documentation strategy so Kiali appears both in dedicated Kiali example flow and in `custom-chart-and-image-overrides`.
4. Define validation approach for Helm release + Kiali CR rendering across standalone and delegated paths.

## Phase 1: Design Outputs

- `research.md`: Decisions and alternatives for Kiali operator behavior mapping, override handling, and validation strategy.
- `data-model.md`: Entities and validation expectations for Kiali operator settings, Kiali CR settings, and Istio delegation wrapper.
- `contracts/module-interface.md`: Interface contract for `modules/kiali` and Istio `configs.kiali` delegation, including compatibility rules.
- `quickstart.md`: Maintainer execution flow for implementing, validating, and documenting the feature.

Agent context regeneration skipped (not explicitly requested).

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| N/A | N/A | N/A |
