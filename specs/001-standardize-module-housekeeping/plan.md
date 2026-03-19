# Implementation Plan: Repository Module Housekeeping

**Branch**: `001-standardize-module-housekeeping` | **Date**: 2026-03-19 | **Spec**: `/Users/aram.karapetzan/Development/dasmeta/terraform/terraform-any-shared/specs/001-standardize-module-housekeeping/spec.md`
**Input**: Feature specification from `/specs/001-standardize-module-housekeeping/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

Standardize repository-wide Terraform module housekeeping without changing
module behavior. The implementation will classify maintained modules, normalize
documentation and structural support artifacts, align validation coverage with
the maintained inventory, and document explicit exceptions for support-only or
non-standard directories.

## Technical Context

**Terraform/OpenTofu Version**: Terraform `~> 1.3` is the dominant baseline
across maintained modules; some modules currently use `version.tf` while others
use `versions.tf`  
**Providers / Upstream Modules**: Mixed provider set across the repository
(commonly Helm, Kubernetes, Kubectl, and provider-specific integrations); no
new upstream module adoption is in scope  
**Target Module Path**: Repository-wide `modules/*` inventory, with
`modules/k8s` treated as a support/asset directory unless future evidence
proves it is a maintained consumer-facing module  
**Examples / Tests in Scope**: All module `examples/`, `example/`, and `tests/`
directories plus missing coverage that must be standardized or explicitly
excepted  
**Automation Gates**: `.pre-commit-config.yaml`,
`.github/workflows/pre-commit.yaml`, `.github/workflows/checkov.yaml`,
`.github/workflows/tflint.yaml`, `.github/workflows/terraform-test.yaml`, and
`.github/workflows/tfsec.yaml`  
**Target Platform**: GitHub-hosted Terraform module repository containing
primarily Kubernetes/Helm-oriented modules plus external service integrations  
**Constraints**: Housekeeping only; no runtime behavior changes; no interface
widening; preserve opinionated wrapper patterns; document standards exceptions
explicitly; keep changes within the current repository  
**Scale/Scope**: 21 likely maintained top-level module directories, nested
module families under `modules/keeper-reader/modules/*` and
`modules/onepassword/module/get-data/*`, plus shared repository automation and
guidance files

### Agent Context Compatibility

**Language/Version**: Terraform ~> 1.3  
**Primary Dependencies**: GitHub Actions, pre-commit, terraform-docs, tflint,
tfsec, checkov, semantic-release  
**Storage**: N/A  
**Project Type**: Terraform module repository

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

Gate result before Phase 0: PASS. The feature is repository-scoped, does not
request runtime or interface changes, and any file renames or naming
normalization that could create a standards conflict will be treated as an
approval gate rather than assumed safe.

## Project Structure

### Documentation (this feature)

```text
specs/001-standardize-module-housekeeping/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── maintained-module-inventory.md
│   └── validation-coverage.md
└── tasks.md
```

### Source Code (repository root)

```text
modules/
├── defectdojo/
├── event-exporter/
├── gateway-api-crds/
├── github-actions-runner/
├── gitlab-runner/
├── goldilocks/
├── horizon-monitor/
├── istio/
├── kafka/
├── keeper-reader/
├── kyverno/
├── loki/
├── minio/
├── mongodb/
├── mongodb-bi-connector/
├── onepassword/
├── onepassword_to_secret_manager/
├── qdrant/
├── renovate-bot/
├── sentry/
├── service/
├── supabase/
└── k8s/                 # Support/asset directory; not part of maintained-module baseline unless reclassified

.github/workflows/
.pre-commit-config.yaml
```

**Structure Decision**: Treat the repository as a multi-module Terraform
catalog. The implementation will standardize top-level maintained modules,
related nested module families where they are part of a maintained module
surface, and the repository-level workflows that validate those modules.

## Phase 0 Research

Research findings are captured in
`/Users/aram.karapetzan/Development/dasmeta/terraform/terraform-any-shared/specs/001-standardize-module-housekeeping/research.md`.
All Technical Context unknowns are resolved; no `NEEDS CLARIFICATION` items
remain.

## Phase 1 Design Artifacts

- Data model:
  `/Users/aram.karapetzan/Development/dasmeta/terraform/terraform-any-shared/specs/001-standardize-module-housekeeping/data-model.md`
- Contracts:
  `/Users/aram.karapetzan/Development/dasmeta/terraform/terraform-any-shared/specs/001-standardize-module-housekeeping/contracts/maintained-module-inventory.md`
  `/Users/aram.karapetzan/Development/dasmeta/terraform/terraform-any-shared/specs/001-standardize-module-housekeeping/contracts/validation-coverage.md`
- Quickstart:
  `/Users/aram.karapetzan/Development/dasmeta/terraform/terraform-any-shared/specs/001-standardize-module-housekeeping/quickstart.md`

## Current State

- Starting module path: repository-wide `modules/*`
- Related submodules in scope:
  `modules/keeper-reader/modules/*`,
  `modules/onepassword/module/get-data/*`
- Repository automation files in scope:
  `.pre-commit-config.yaml`,
  `.github/workflows/pre-commit.yaml`,
  `.github/workflows/checkov.yaml`,
  `.github/workflows/tflint.yaml`,
  `.github/workflows/terraform-test.yaml`,
  `.github/workflows/tfsec.yaml`
- Existing standard files present: strong module coverage exists in
  `defectdojo`, `event-exporter`, `gateway-api-crds`, `gitlab-runner`,
  `horizon-monitor`, `istio`, `kyverno`, and `renovate-bot`
- Existing gaps or inconsistencies:
  missing `examples/` or `tests/` across many modules; missing `outputs.tf`,
  `versions.tf` or `providers.tf` in several maintained modules; singular
  `example/`; `provider.tf`; `version.tf`; typo `varables.tf`; likely mistaken
  `locales.tf`; nonstandard `deploy.tf`; partial workflow matrices; no explicit
  maintained-module inventory

## Comparison Against Internal Standards

- Module design boundary: the feature remains repository-scoped housekeeping and
  preserves each module's existing responsibility boundary
- Variable and output alignment: this feature may add missing documentation or
  structural support files but must not broaden consumer inputs or alter output
  semantics
- Documentation, examples, and tests alignment: repo baseline is inconsistent;
  README narrative quality varies, examples/tests coverage is uneven, and test
  structure is not standardized
- Version and provider alignment: file naming is inconsistent (`provider.tf`,
  `version.tf`, missing version/provider files); changes must normalize or
  explicitly except those cases without changing compatibility meaning

## New-Module Sourcing Assessment

- Use this section only for new-module creation.
- Target cloud: N/A
- Provider collection checked: N/A
- Candidate upstream modules considered: N/A
- Selected upstream wrapper baseline: N/A
- Why this is the closest scope match: N/A
- Wrapper-added usability or interface improvements: N/A
- Fallback required: No
- Fallback reason: Existing-module housekeeping only

## Comparison Against Scratch Template

- Use this section only when new-module creation falls back to direct
  resource-based scaffolding.
- Relevant upstream patterns: N/A
- Patterns intentionally not copied: N/A

## Proposed File Changes

- Files to create:
  maintained-module inventory documentation,
  validation coverage documentation,
  missing or standardized module support artifacts (`README.md` preambles,
  `examples/`, `tests/`, standard file wrappers or renamed files) where they
  can be added without behavior change
- Files to update:
  selected module `README.md`, example/test directories, standard Terraform file
  names, `.pre-commit-config.yaml`, and workflow matrices for `checkov`,
  `tflint`, `terraform-test`, and `pre-commit`
- Files to leave unchanged:
  Terraform runtime logic, module input/output semantics, provider arguments,
  default values, and infrastructure behavior

## Risks and Approvals

- Potential breaking changes:
  none planned; if file renames or validation changes would affect downstream
  usage or automation assumptions, stop and request approval
- Potential interface-widening changes:
  none; any request to expose more inputs, defaults, or provider options is out
  of scope for this feature
- Conflicts requiring approval:
  renaming nonstandard files when the repository may rely on those exact names;
  classifying ambiguous directories as maintained vs excepted; expanding
  workflow scope if a module cannot yet satisfy the validation baseline
- Fallback sources needed:
  none beyond repository constitution and bundled internal standards

## Execution Notes

- Recommended order of edits:
  1. Create maintained-module inventory and exception model.
  2. Normalize repository-level validation scope and workflow documentation.
  3. Standardize module README/example/test expectations.
  4. Normalize non-behavioral file naming and structure where safe.
  5. Re-run documentation and validation tooling.
- Validation after edits:
  `pre-commit run --all-files`,
  `terraform fmt -check -recursive`,
  repo workflow matrix review for maintained modules,
  spot verification that no Terraform resource or interface logic changed

## Post-Design Constitution Check

- [x] Change remains within repository scope and coherent module housekeeping
      responsibility.
- [x] Wrapper interfaces remain unchanged; no widening or weakened defaults are
      introduced by the plan.
- [x] README, examples, and tests are part of the planned edit surface.
- [x] Version/provider file impacts are explicitly reviewed as housekeeping
      normalization work.
- [x] No breaking changes are planned; potential standards conflicts are called
      out as approval gates.

Gate result after Phase 1: PASS.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| None | N/A | N/A |
