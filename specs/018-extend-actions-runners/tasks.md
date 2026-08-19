# Tasks: Extend Legacy GitHub Actions Runners

**Input**: Design documents from `/specs/018-extend-actions-runners/`
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/module-interface.md`, `quickstart.md`

**Tests**: Required because module behavior, inputs, outputs, provider behavior,
and rendered resources change. Mock-provider tests must be written before each
behavioral implementation slice.

**Organization**: Tasks are grouped by user story and preserve the historical
single-repository path while adding the YAML/Terraform Cloud path and new target
scopes.

## Phase 1: Setup and Governance Baseline

**Purpose**: Confirm scope, approval, and module-change evidence before source edits

- [x] T001 Confirm `modules/github-actions-runner` is the only module in scope and record the approved interface widening in `specs/018-extend-actions-runners/plan.md`
- [x] T002 Verify `specs/018-extend-actions-runners/spec.md`, `plan.md`, and `tasks.md` identify all module, example, test, documentation, and automation paths required by the module-change gate

---

## Phase 2: Foundational Compatibility Baseline

**Purpose**: Establish explicit compatibility and test structure shared by every story

**⚠️ CRITICAL**: Complete before user-story implementation.

- [x] T003 Add Terraform `~> 1.3`, Helm `~> 2.0`, and kubectl `~> 1.14` declarations in `modules/github-actions-runner/versions.tf` while retaining actual kubectl configuration in `modules/github-actions-runner/providers.tf`
- [x] T004 Create mock Helm and kubectl provider scaffolding in `modules/github-actions-runner/tests/runner_modes.tftest.hcl`
- [x] T005 [P] Create the numbered generic consumer scaffold in `modules/github-actions-runner/examples/basic/0-setup.tf` and `modules/github-actions-runner/examples/basic/1-example.tf`

**Checkpoint**: Compatibility and verification scaffolding exist before behavior changes.

---

## Phase 3: User Story 1 - Deploy Through YAML Infrastructure (Priority: P1) 🎯 MVP

**Goal**: Allow a Terraform Cloud/YAML consumer to use injected Kubernetes credentials and a pre-existing GitHub authentication Secret without committing a token.

**Independent Test**: Mock-provider plans accept existing-Secret authentication with `kubectl_config_path = null`, render the correct Helm Secret reference, redact token mode, and reject missing or ambiguous authentication.

### Tests for User Story 1

- [x] T006 [US1] Add failing external-Secret, nullable-kubeconfig, token-sensitivity, missing-auth, and mixed-auth test runs to `modules/github-actions-runner/tests/runner_modes.tftest.hcl`

### Implementation for User Story 1

- [x] T007 [US1] Make the existing token nullable/sensitive and add validated Secret, namespace, and chart-version inputs in `modules/github-actions-runner/variables.tf`
- [x] T008 [US1] Honor nullable `kubectl_config_path` and environment credential fallback in `modules/github-actions-runner/providers.tf`
- [x] T009 [US1] Add authentication-selection locals and render sensitive token or existing-Secret Helm values with explicit runner dependencies in `modules/github-actions-runner/locals.tf` and `modules/github-actions-runner/main.tf`
- [x] T010 [P] [US1] Add generic YAML/Terraform Cloud and existing-Secret usage to `modules/github-actions-runner/examples/basic/1-example.tf` and `modules/github-actions-runner/README.md`
- [x] T011 [US1] Run `terraform test` from `modules/github-actions-runner` and confirm all User Story 1 runs pass without live credentials

**Checkpoint**: The module is independently consumable by YAML/Terraform Cloud with an external auth Secret.

---

## Phase 4: User Story 2 - Choose Repository or Organization Scope (Priority: P2)

**Goal**: Support one legacy repository, several explicit repositories, or one organization from a single module instance.

**Independent Test**: Mock-provider plans render one deterministic manifest per unique repository or one organization manifest and reject mixed repository/organization scope.

### Tests for User Story 2

- [x] T012 [US2] Add failing multi-repository, organization, duplicate-target, deterministic-name, and mixed-scope test runs to `modules/github-actions-runner/tests/runner_modes.tftest.hcl`

### Implementation for User Story 2

- [x] T013 [US2] Add the optional, inline-documented grouped `runner_scope` input and its internal validation in `modules/github-actions-runner/variables.tf`
- [x] T014 [US2] Derive effective targets, deterministic Kubernetes names, and target mode in `modules/github-actions-runner/locals.tf`
- [x] T015 [US2] Generalize `modules/github-actions-runner/runner.yaml` and add keyed multi-repository/organization manifests in `modules/github-actions-runner/main.tf`
- [x] T016 [P] [US2] Add non-sensitive target, mode, and runner-name outputs in `modules/github-actions-runner/outputs.tf`
- [x] T017 [P] [US2] Document repository collection and organization examples in `modules/github-actions-runner/README.md`
- [x] T018 [US2] Run `terraform test` from `modules/github-actions-runner` and confirm all User Story 2 runs pass

**Checkpoint**: All three target modes are independently valid and mutually exclusive.

---

## Phase 5: User Story 3 - Preserve Existing Consumers (Priority: P3)

**Goal**: Prove that the historical input shape, target, name, namespace, token flow, and resource addresses remain compatible.

**Independent Test**: A historical single-repository mock-provider plan uses `repo_name`, retains `runner_name`, creates the token-backed chart Secret, and addresses the existing Helm and manifest resources.

### Tests for User Story 3

- [x] T019 [US3] Add a failing historical single-repository compatibility run with resource-address and rendered-value assertions to `modules/github-actions-runner/tests/runner_modes.tftest.hcl`

### Implementation for User Story 3

- [x] T020 [US3] Preserve `helm_release.test` and `kubectl_manifest.pv_mongo_main[0]` for legacy mode while integrating the new scope path in `modules/github-actions-runner/main.tf`
- [x] T021 [P] [US3] Normalize touched README examples to generic identifiers and document zero-change legacy usage in `modules/github-actions-runner/README.md`
- [x] T022 [US3] Run `terraform test` and compare historical outputs and resource addresses against the compatibility contract in `specs/018-extend-actions-runners/contracts/module-interface.md`

**Checkpoint**: Existing single-repository consumers can upgrade without renaming inputs or migrating state addresses.

---

## Phase 6: Documentation, Coverage, and Quality Gates

**Purpose**: Align generated documentation and close the module's validation exception

- [x] T023 Regenerate the terraform-docs block in `modules/github-actions-runner/README.md` and verify all new inputs/outputs match the live interface
- [x] T024 Add `modules/github-actions-runner` to `.github/workflows/terraform-test.yaml` and update `docs/module-housekeeping/exceptions.md`, `maintained-modules.md`, and `validation-coverage.md` to close the missing-example exclusion
- [x] T025 Run `terraform fmt -check -recursive`, `terraform init -backend=false`, `terraform validate`, and `terraform test` for `modules/github-actions-runner`
- [x] T026 Run applicable pre-commit, tflint, Checkov, and tfsec checks for `modules/github-actions-runner` and record any tool-unavailable limitation
- [x] T027 Review all changed module artifacts for credentials, customer-specific names, unapproved breaking changes, wrapper drift, and complete Speckit evidence under `specs/018-extend-actions-runners/`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1** has no dependency.
- **Phase 2** depends on Phase 1 and blocks all behavior changes.
- **User Story 1** depends on Phase 2 and establishes shared authentication/provider behavior.
- **User Story 2** depends on User Story 1 because it reuses the same manifest and validation foundation.
- **User Story 3** depends on User Stories 1 and 2 so compatibility is checked against the complete interface.
- **Quality gates** depend on every selected user story.

### Within Each User Story

- Add failing mock-provider tests before implementation.
- Update inputs and locals before resource wiring.
- Update examples/docs after the live interface is stable.
- Complete the story-specific test run before the next story.

### Parallel Opportunities

- T005 can proceed independently after T003/T004 establish the target structure.
- T010 can update the example and README after T007-T009 while tests are reviewed.
- T016 and T017 touch separate files after T013-T015.
- T021 can run alongside compatibility test review after T020.

## Implementation Strategy

### MVP First

1. Complete governance and compatibility foundations.
2. Deliver User Story 1: existing Secret plus Terraform Cloud credentials.
3. Validate independently before adding target modes.

### Incremental Delivery

1. YAML/Terraform Cloud compatibility.
2. Multiple repositories and organization scope.
3. Historical consumer compatibility proof.
4. Documentation generation and repository gates.

## Notes

- New grouped fields in `variables.tf` require inline end-of-line comments.
- Do not add real organization/repository identifiers or token-shaped examples.
- The consumer infrastructure Setup is deferred until a module version is
  released; never pin an unreleased registry version.

## Verification Record

- `terraform fmt -check -recursive modules/github-actions-runner`: passed.
- Module `terraform init -backend=false` and `terraform validate`: passed.
- `terraform test`: passed, 9 runs and 0 failures after review resolution.
- Basic example `terraform init -backend=false` and `terraform validate`: passed.
- Checkov: passed locally; its optional Prisma guideline lookup was unavailable
  in the restricted network environment.
- tfsec: passed with no detected problems.
- `pre-commit` and `tflint`: not installed in the local environment; their CI
  workflows remain applicable to the changed module.

## Phase 7: Pull Request Review Resolution

**Purpose**: Resolve the approved safety, determinism, and documentation findings
from the first human review without removing the legacy internal provider.

- [x] T028 Add failing tests for missing explicit targets and same-prefix scoped
  runner-name collisions in `modules/github-actions-runner/tests/runner_modes.tftest.hcl`
- [x] T029 Remove the customer-specific `repo_name` default, validate explicit
  legacy targets, and add the target precondition in
  `modules/github-actions-runner/variables.tf`, `locals.tf`, and `main.tf`
- [x] T030 Include the full runner name in scoped runner hashes in
  `modules/github-actions-runner/locals.tf`
- [x] T031 Document the internal-provider module-meta-argument limitation and
  the `repo_name` to `runner_scope.repositories` replacement behavior in
  `modules/github-actions-runner/README.md`
- [x] T032 Pin `chart_version` in the executable example and align generated
  README input documentation
- [x] T033 Update the interface contract and quickstart with the approved
  explicit-target requirement and deferred provider migration
- [x] T034 Run formatting, validation, module tests, example validation,
  terraform-docs, Checkov, and tfsec; verify no customer-specific identifier
  remains in module artifacts

## Phase 8: Terraform Cloud Apply Correction

**Purpose**: Correct the environment-credential path after a live remote apply
proved that a null config path alone did not prevent kubectl from falling back to
an unavailable local configuration.

- [x] T035 Record the live Terraform Cloud failure and refine the null-path
  contract in `spec.md`, `plan.md`, and `research.md`
- [x] T036 Explicitly disable kubeconfig loading when `kubectl_config_path` is
  null while preserving historical file loading for non-null paths in
  `modules/github-actions-runner/providers.tf`
- [x] T037 Align the module README and quickstart with the corrected provider
  behavior
- [x] T038 Run formatting, module tests, example validation, and an
  environment-credential diagnostic plan
