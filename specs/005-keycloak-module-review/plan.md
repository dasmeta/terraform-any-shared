# Implementation Plan: Keycloak module production readiness

**Branch**: `[005-keycloak-module-review]` | **Date**: 2026-05-05 | **Spec**: `specs/005-keycloak-module-review/spec.md`
**Input**: Feature specification from `specs/005-keycloak-module-review/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

Harden `modules/keycloak` as an opinionated wrapper around the `codecentric/keycloakx` Helm chart for production operation on Kubernetes with an external database.

This work focuses on:

- Production-aligned hostname and reverse-proxy behavior suitable for TLS termination at the ingress/LB
- Explicit clustering/cache configuration aligned to Keycloak upstream guidance (JDBC_PING default stack)
- Observability improvements (metrics, optional Prometheus Operator ServiceMonitor, user event metrics, log controls)
- Operational safety knobs (timeouts, queued request limit, termination grace)

Docs and examples are updated to remain safe-to-commit (no environment-specific kubeconfig paths or secrets).

## Technical Context

<!--
  ACTION REQUIRED: Replace the content in this section with the technical details
  for the project. The structure here is presented in advisory capacity to guide
  the iteration process.
-->

**Terraform/OpenTofu Version**: Terraform ~> 1.3  
**Providers / Upstream Modules**: `hashicorp/helm` (~> 2.0), `hashicorp/kubernetes` (~> 2.0), upstream Helm chart `codecentric/keycloakx`  
**Target Module Path**: `modules/keycloak`  
**Examples / Tests in Scope**: `modules/keycloak/examples/basic`, `modules/keycloak/tests/basic`  
**Automation Gates**: pre-commit (terraform fmt, terraform-docs)  
**Target Platform**: Kubernetes cluster (EKS-compatible) + consumer-managed external database (PostgreSQL)  
**Constraints**:
- Keep wrapper opinionated; avoid broad pass-through
- No breaking changes or unapproved interface widening
- Keep examples and README safe to commit (no real secrets or personal kubeconfig paths)
**Scale/Scope**: module + docs/examples/tests only

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] Change stays within one coherent module responsibility and the current
      repository scope.
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
specs/005-keycloak-module-review/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
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
modules/keycloak/
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
├── README.md
├── examples/
└── tests/
```

**Structure Decision**: Work stays limited to `modules/keycloak` and its example/test directories; no repository-wide automation changes.

## Phase 0: Research Summary

See `research.md` for distilled guidance and decisions based on Keycloak upstream documentation and the chart behavior.

## Phase 1: Design & Contracts

- `data-model.md` captures the configuration entities and invariants for the wrapper inputs.
- `quickstart.md` provides a minimal, safe-to-commit workflow for consumers to validate behavior.
- No external interface contracts are required beyond the module variables/outputs and documentation.

## Complexity Tracking

No constitution violations requiring justification.
