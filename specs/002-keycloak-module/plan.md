# Implementation Plan: Keycloak Helm Wrapper Module

**Branch**: `002-keycloak-module` | **Date**: 2026-03-26 | **Spec**: `/Users/aram.karapetzan/Development/dasmeta/terraform/terraform-any-shared/specs/002-keycloak-module/spec.md`
**Input**: Feature specification from `/specs/002-keycloak-module/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

Create a new opinionated Terraform module at `modules/keycloak` that deploys
Keycloak through the `codecentric/keycloakx` Helm chart while keeping the
consumer interface intentionally narrow. The module will target the standard
deployment path only: Keycloak on Kubernetes with a consumer-managed external
database, consumer-managed ingress controller and certificates, curated
bootstrap secret handling, aligned documentation/examples/tests, and repository
workflow coverage consistent with other maintained Helm-backed modules.

## Technical Context

**Terraform/OpenTofu Version**: Terraform `~> 1.3`, aligned with the
repository baseline for maintained modules  
**Providers / Upstream Modules**: `hashicorp/helm` for release management,
`hashicorp/kubernetes` for optional managed Secret creation when raw bootstrap
credentials are supplied, upstream baseline `codecentric/keycloakx` Helm chart  
**Target Module Path**: `modules/keycloak`  
**Examples / Tests in Scope**: `modules/keycloak/examples/basic/`,
`modules/keycloak/tests/basic/`, and `modules/keycloak/README.md`  
**Automation Gates**: `.pre-commit-config.yaml`,
`.github/workflows/checkov.yaml`, `.github/workflows/tflint.yaml`,
`.github/workflows/terraform-test.yaml`, and repo-wide `tfsec` coverage  
**Target Platform**: Existing Kubernetes cluster with configured Helm/Kubernetes
providers, consumer-managed external database, and consumer-managed ingress/TLS
dependencies  
**Constraints**: New module only; preserve opinionated wrapper boundary; no
generic Helm values pass-through; first release supports external database
mode only; ingress configuration is application-facing only and does not manage
the ingress controller or certificates; existing secret references are the
preferred credential path and mixed credential-source inputs must be rejected
per credential scope  
**Scale/Scope**: One new maintained module plus its README, examples, tests,
version/provider declarations, and workflow matrix entries

### Agent Context Compatibility

**Language/Version**: Terraform ~> 1.3  
**Primary Dependencies**: Helm provider, Kubernetes provider, GitHub Actions, pre-commit, terraform-docs, tflint, checkov  
**Storage**: Consumer-managed external database; Kubernetes Secret-backed bootstrap credentials  
**Project Type**: Terraform Helm wrapper module

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

Gate result before Phase 0: PASS. The feature introduces one new module within
the existing repository boundary, wraps an upstream chart instead of rebuilding
Keycloak from direct resources, and keeps interface widening explicitly out of
scope for the first version.

## Project Structure

### Documentation (this feature)

```text
specs/002-keycloak-module/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── keycloak-module-interface.md
│   └── keycloak-validation-scope.md
└── tasks.md
```

### Source Code (repository root)

```text
modules/keycloak/
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
├── README.md
├── examples/
│   └── basic/
└── tests/
    └── basic/

.github/workflows/
.pre-commit-config.yaml
```

**Structure Decision**: Implement Keycloak as a new maintained top-level Helm
wrapper module with dedicated example and test scaffolding. Repository-level
workflow files remain in scope because the new module must be added to the same
maintained-module validation path used for comparable modules.

## Phase 0 Research

Research findings are captured in
`/Users/aram.karapetzan/Development/dasmeta/terraform/terraform-any-shared/specs/002-keycloak-module/research.md`.
All Technical Context decisions needed for planning are resolved; no
`NEEDS CLARIFICATION` items remain.

## Phase 1 Design Artifacts

- Data model:
  `/Users/aram.karapetzan/Development/dasmeta/terraform/terraform-any-shared/specs/002-keycloak-module/data-model.md`
- Contracts:
  `/Users/aram.karapetzan/Development/dasmeta/terraform/terraform-any-shared/specs/002-keycloak-module/contracts/keycloak-module-interface.md`
  `/Users/aram.karapetzan/Development/dasmeta/terraform/terraform-any-shared/specs/002-keycloak-module/contracts/keycloak-validation-scope.md`
- Quickstart:
  `/Users/aram.karapetzan/Development/dasmeta/terraform/terraform-any-shared/specs/002-keycloak-module/quickstart.md`

## Current State

- Starting module path: `modules/keycloak` does not exist yet.
- Comparable repository patterns exist in maintained Helm modules such as
  `modules/defectdojo`, `modules/gitlab-runner`, `modules/horizon-monitor`, and
  `modules/qdrant`.
- Repository workflow matrices currently cover maintained modules explicitly via
  path lists in `.github/workflows/checkov.yaml`,
  `.github/workflows/tflint.yaml`, and `.github/workflows/terraform-test.yaml`.
- `terraform-test` coverage expects module-local example or test scaffolding;
  the new module can enter that workflow if `examples/basic` and/or
  `tests/basic` are created with a runnable Terraform consumer path.

## Comparison Against Internal Standards

- Module design boundary: stays within one module responsibility, deploying
  Keycloak only and leaving databases, ingress controllers, DNS, TLS, and
  secret backends outside the module boundary.
- Variable and output alignment: the module will expose only curated inputs for
  the common Keycloak case and useful release outputs such as release identity,
  status, chart version, and Helm metadata.
- Documentation, examples, and tests alignment: README, `examples/basic`, and
  `tests/basic` are first-class deliverables in this plan, not follow-up work.
- Version and provider alignment: the module will declare Terraform/provider
  compatibility explicitly in `versions.tf`; any added provider usage must be
  justified by the final secret-handling design rather than inferred later.

## New-Module Sourcing Assessment

- Target platform: Kubernetes application deployment through Helm
- Provider collection checked: repository-local Helm wrapper patterns and
  maintained-module validation expectations
- Candidate upstream modules considered: `codecentric/keycloakx` Helm chart
- Selected upstream wrapper baseline: `codecentric/keycloakx`
- Why this is the closest scope match: it matches the requested delivery model,
  keeps release management inside Helm, and avoids re-implementing Keycloak
  deployment logic from lower-level Kubernetes resources
- Wrapper-added usability or interface improvements: curated Terraform inputs,
  explicit external-dependency boundaries, deterministic bootstrap credential
  handling, repository-aligned outputs, and maintained-module docs/examples/tests
- Fallback required: No
- Fallback reason: the selected upstream chart is already the requested baseline

## Comparison Against Scratch Template

- Use this section only when new-module creation falls back to direct
  resource-based scaffolding.
- Relevant upstream patterns: N/A
- Patterns intentionally not copied: N/A

## Proposed File Changes

- Files to create:
  `modules/keycloak/main.tf`,
  `modules/keycloak/variables.tf`,
  `modules/keycloak/outputs.tf`,
  `modules/keycloak/versions.tf`,
  `modules/keycloak/README.md`,
  `modules/keycloak/examples/basic/*`,
  `modules/keycloak/tests/basic/*`
- Files to update:
  `.github/workflows/checkov.yaml`,
  `.github/workflows/tflint.yaml`,
  `.github/workflows/terraform-test.yaml`,
  `.pre-commit-config.yaml` only if the new module requires repository-level
  doc-generation or formatting scope changes beyond current defaults
- Files to leave unchanged:
  unrelated modules, repository support-only paths, and any workflow scopes not
  needed to validate the new Keycloak module

## Risks and Approvals

- Potential breaking changes:
  none expected because this is a new module; workflow updates must avoid
  regressing existing matrices
- Potential interface-widening changes:
  adding a generic `values`, `custom_values`, or similar pass-through input;
  exposing low-frequency chart internals; making bundled database or ingress
  controller ownership part of the first version
- Conflicts requiring approval:
  any proposal to broaden the interface beyond curated inputs, skip maintained
  module validation inclusion, or choose a direct-resource implementation over
  the chart wrapper baseline
- Fallback sources needed:
  none beyond the repository constitution, existing maintained Helm modules,
  and the feature spec

## Execution Notes

- Recommended order of edits:
  1. Scaffold `modules/keycloak` with explicit versions/providers and a narrow
     variable surface.
  2. Implement Helm values assembly and bootstrap-credential source selection.
  3. Add outputs, README narrative, and terraform-docs block.
  4. Add `examples/basic` and `tests/basic` consumer paths.
  5. Add workflow matrix entries for the new maintained module.
  6. Run formatting and validation, then reconcile generated docs.
- Validation after edits:
  `terraform fmt -check -recursive modules/keycloak`,
  `terraform -chdir=modules/keycloak init -backend=false`,
  `terraform -chdir=modules/keycloak validate`,
  `terraform -chdir=modules/keycloak/examples/basic init -backend=false`,
  `terraform -chdir=modules/keycloak/examples/basic validate`,
  `terraform -chdir=modules/keycloak/tests/basic init -backend=false`,
  `terraform -chdir=modules/keycloak/tests/basic validate`,
  `PRE_COMMIT_HOME=/tmp/pre-commit-cache python3 -m pre_commit run --all-files`

## Post-Design Constitution Check

- [x] Change remains within one coherent Keycloak module responsibility and the
      current repository scope.
- [x] The wrapper interface stays opinionated and intentionally excludes broad
      upstream pass-through inputs.
- [x] README, example, and test work are explicitly part of the planned edit
      surface.
- [x] Version/provider impacts are explicit because the plan names `versions.tf`
      and the Helm/Kubernetes provider decision.
- [x] No breaking changes are planned; approval-gated interface widening and
      standards conflicts are explicitly called out.

Gate result after Phase 1: PASS.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**
