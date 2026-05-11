# Implementation Plan: Helm Archive Chart Sources and Kiali Apply Readiness

**Branch**: `007-helm-archive-kiali-wait` | **Date**: 2026-05-11 | **Spec**: `/specs/007-helm-archive-kiali-wait/spec.md`
**Input**: Feature specification from `/specs/007-helm-archive-kiali-wait/spec.md`

## Summary

Finalize two module-impacting changes that already exist in the worktree: support direct HTTP(S) `.tgz` Helm chart archive URLs in Istio and Kiali chart fields, and make Kiali custom resource creation wait for readiness. The implementation keeps the existing wrapper interface and defaults, changes only Helm release argument derivation and Kiali manifest apply behavior, and records Speckit evidence for the module-change gate.

## Technical Context

**Terraform/OpenTofu Version**: Terraform `~> 1.3`  
**Providers / Upstream Modules**: `hashicorp/helm (~> 2.0)`, `gavinbunney/kubectl (~> 1.14)`, repository-local `modules/kiali` delegation from `modules/istio`  
**Target Module Path**: `modules/istio`, `modules/kiali`  
**Examples / Tests in Scope**: `modules/istio/examples/chart-direct-tgz-sources`, existing `modules/kiali/examples/basic`, existing `modules/istio/examples/kiali-observability`  
**Automation Gates**: `terraform fmt`, `terraform validate` for affected examples where provider initialization is available, `pre-commit` terraform formatting/docs hooks when available  
**Target Platform**: Kubernetes clusters where Istio, Gateway API resources, and Kiali are installed through Terraform-managed Helm and kubectl resources  
**Constraints**: Preserve opinionated wrapper shape; no new required inputs; no breaking changes; do not commit generated Terraform state; new Terraform content must use neutral example naming  
**Scale/Scope**: Existing Istio and Kiali modules plus one direct chart source Istio example and Speckit artifacts

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] Change stays within one coherent module responsibility and the current repository scope.
- [x] Consumer interface remains opinionated; any interface widening is explicitly documented and approved.
- [x] `README.md`, `examples/`, and `tests/` updates are listed for every behavior or interface change.
- [x] `versions.tf` or `version.tf` and `providers.tf` impacts are reviewed and made explicit when compatibility changes.
- [x] Breaking changes, weakened defaults, or standards conflicts are recorded with approval status before implementation.

Post-design re-check: PASS. The change reuses existing chart fields, adds no new provider requirements, and introduces no breaking input changes.

## Pre-change Module Plan

### Current Repository Module State

- `modules/istio` installs Gateway API CRDs, Istio base, istiod, optional ingress gateways, Gateway API resource chart, and optional Kiali delegation.
- `modules/kiali` installs the Kiali operator Helm chart and optionally creates a `kiali.io/v1alpha1` `Kiali` custom resource through `kubectl_manifest`.
- The current dirty worktree already includes direct-chart URL detection in `modules/istio/main.tf`, direct-chart URL detection in `modules/kiali/main.tf`, chart input description updates in both modules, and `wait = true` for the Kiali CR.

### Gaps Versus Bundled Internal Standards

- The implementation is scoped and preserves defaults, which aligns with the internal module standards.
- The direct chart source example must use original upstream Helm chart archive URLs and avoid registry-specific derivation logic.
- Generated Terraform state, `.terraform/`, lock files, and `*.tfstate*` files must remain ignored and not be staged.
- README/generated terraform-docs output must be reviewed because behavior-affecting chart descriptions changed.

### Wrapper Preservation Assessment

- The wrapper remains opinionated: the module still exposes the same grouped `configs` object and does not expose a broad Helm provider pass-through.
- The accepted value set for existing chart strings widens in a bounded way to include HTTP(S) chart archives.
- Repository/version suppression is derived internally from chart source shape, avoiding additional inputs such as `chart_is_url`.

### Provider Collection / Upstream Baseline

- New provider-maintained module sourcing is not applicable because this is an extension of existing modules, not new-module creation.
- Baseline is the Helm provider `helm_release` resource contract for chart references plus the existing Kiali `kubectl_manifest` resource.
- No fallback to direct resource scaffolding or upstream scratch template is required.

### Constitution Repository Source

- Shared repository governance source: `.specify/memory/constitution.md` version `1.0.0`.
- Local module skill references used: `terraform-module-developer` internal module standards and planning checklist.

### Speckit Evidence

- Speckit package path: `specs/007-helm-archive-kiali-wait/`.
- Required gate files: `spec.md`, `plan.md`, and `tasks.md`.
- Additional design evidence: `research.md`, `data-model.md`, `contracts/module-interface.md`, and `quickstart.md`.
- Downstream module-change gate status: expected to pass once this package is committed with affected module paths named in each required artifact.

### Proposed File Changes

```text
specs/007-helm-archive-kiali-wait/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── module-interface.md
└── tasks.md

modules/istio/
├── main.tf
├── variables.tf
├── README.md
└── examples/
    └── chart-direct-tgz-sources/

modules/kiali/
├── main.tf
├── variables.tf
└── README.md
```

**Structure Decision**: Keep behavior changes inside existing module files and store Speckit evidence under a new feature package. Use the example directory only to demonstrate archive-backed chart and image overrides.

### Potential Breaking Changes

- None expected. Defaults and existing repository-backed chart behavior are preserved.

### Potential Interface-widening Changes

- Bounded value widening: existing chart string fields now accept HTTP(S) archive URLs. This is approved by the user's request and does not add new inputs or broaden into raw Helm provider pass-through.

### Conflicts Requiring Approval

- None blocking implementation.
- Standards cleanup required before merge: ensure ignored Terraform runtime artifacts are not staged.

## Phase 0: Research Plan

1. Confirm how repository-backed chart names differ from direct HTTP(S) archive URLs in existing Helm release arguments.
2. Confirm a simple deterministic Terraform expression can identify direct HTTP(S) chart URLs without changing variable schema.
3. Confirm Kiali CR readiness should be enforced at the `kubectl_manifest` resource rather than through a new consumer input.
4. Confirm validation commands for affected module and example paths.

## Phase 1: Design Outputs

- `research.md`: decisions and alternatives for chart URL detection, repository/version suppression, and Kiali wait behavior.
- `data-model.md`: internal entities for chart sources and Kiali readiness.
- `contracts/module-interface.md`: consumer-facing compatibility contract for existing chart fields and Kiali CR behavior.
- `quickstart.md`: implementation and validation workflow for maintainers.

Agent context regeneration skipped because this change only adds repository-local Speckit evidence and does not introduce new agent tooling.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Bounded interface value widening | Existing chart fields need to accept direct HTTP(S) chart archives | Adding new parallel URL-specific variables would make the wrapper less clear and duplicate chart source configuration |
