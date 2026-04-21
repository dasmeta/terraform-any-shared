# Implementation Plan: Argo CD module review & hardening

**Branch**: `[003-argocd-module-review]` | **Date**: 2026-04-21 | **Spec**: `spec.md`
**Input**: Feature specification from `specs/003-argocd-module-review/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

Harden and standardize the existing `modules/argocd` Terraform wrapper around the upstream `argoproj/argo-cd` Helm chart. Focus on production-friendly defaults, configurable ingress/helm behaviors, optional autoscaling support, and a safe escape hatch (`extra_configs`), while keeping the module opinionated (not a full values passthrough).

## Technical Context

<!--
  ACTION REQUIRED: Replace the content in this section with the technical details
  for the project. The structure here is presented in advisory capacity to guide
  the iteration process.
-->

**Terraform/OpenTofu Version**: Terraform `~> 1.3`  
**Providers / Upstream Modules**: Helm provider `~> 2.0`; upstream chart `argoproj/argo-cd`  
**Target Module Path**: `modules/argocd`  
**Examples / Tests in Scope**: `modules/argocd/examples/basic` (no dedicated tests directory yet)  
**Automation Gates**: pre-commit (terraform-docs), repo CI as configured  
**Target Platform**: Existing Kubernetes cluster; AWS ALB ingress controller pattern  
**Constraints**:
- Keep wrapper interface opinionated; avoid broad interface widening
- Keep examples free of client-specific hostnames and secrets
**Scale/Scope**: Module code + README + examples + spec artifacts only (no repo-wide refactors)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] Change stays within one coherent module responsibility and the current
      repository scope.
- [x] If Terraform modules or Terraform automation are in scope, the
      `terraform-module-developer` skill is used as the primary workflow guide
      (and any deviations are recorded with rationale).
- [x] Consumer interface remains opinionated; any interface widening is
      explicitly documented and approved.
- [x] `README.md`, `examples/`, and `tests/` updates are listed for every
      behavior or interface change.
- [x] `versions.tf` or `version.tf` and `providers.tf` impacts are reviewed and
      made explicit when compatibility changes.
- [x] Breaking changes, weakened defaults, or standards conflicts are recorded
      with approval status before implementation.

## Project Structure

### Documentation (this feature)

```text
specs/003-argocd-module-review/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command, if needed)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)
<!--
  ACTION REQUIRED: Replace the placeholder tree below with the concrete module
  layout for this feature. Delete unused entries and expand the chosen
  structure with real paths. The delivered plan must not include placeholder
  labels.
-->

```text
modules/argocd/
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
├── README.md
└── examples/
    └── basic/
        ├── 0-setup.tf
        ├── 1-example.tf
        └── README.md
```

**Structure Decision**: Keep the module as a Helm-wrapper module with a narrow interface; rely on `extra_configs` for edge chart values instead of expanding inputs.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No constitution violations requiring justification.
