# Tasks: Add Official GitHub ARC Runner Scale Sets

**Input**: Design documents from `/specs/019-github-scale-set/`  
**Prerequisites**: `spec.md`, `plan.md`, `research.md`, `data-model.md`,
`contracts/module-interface.md`, and `quickstart.md`

**Tests**: Required because this changes module behavior, interface, rendered
Helm releases, examples, and state migration behavior.

## Phase 1: Setup and Compatibility Baseline

- [x] T001 Confirm `modules/github-actions-runner` is the only module in scope and review the existing `helm_release.test` state address in `modules/github-actions-runner/main.tf`.
- [x] T002 Record the official chart values and version decision in `specs/019-github-scale-set/research.md`.

## Phase 2: Foundational Mode Selection

- [x] T003 Add failing legacy-isolation, scale-set Secret, scale-set token, URL, and capacity-bound test runs in `modules/github-actions-runner/tests/runner_modes.tftest.hcl`.
- [x] T004 Add validated `deployment_mode` and inline-documented grouped `scale_set` inputs in `modules/github-actions-runner/variables.tf`.
- [x] T005 Add mode-selection, official chart, authentication, and output locals in `modules/github-actions-runner/locals.tf`.
- [x] T006 Add Terraform state migration metadata and separate legacy versus official Helm release rendering in `modules/github-actions-runner/main.tf`.

## Phase 3: User Story 1 - Run Autoscaled Official Runners (Priority: P1)

**Goal**: Install the official GitHub controller and one queue-driven, Docker-in-Docker runner scale set.

**Independent Test**: Mock-provider plan renders two official releases and no legacy resources with the configured scope, label, capacity, and dind mode.

- [x] T007 [US1] Implement official controller and scale-set Helm values, ordering, chart pins, and Docker-in-Docker mode in `modules/github-actions-runner/main.tf`.
- [x] T008 [US1] Add selected-mode and scale-set-label outputs in `modules/github-actions-runner/outputs.tf`.
- [x] T009 [US1] Run the official external-Secret scale-set Terraform test in `modules/github-actions-runner/tests/runner_modes.tftest.hcl`.

## Phase 4: User Story 2 - Use Existing GitHub Credentials Safely (Priority: P2)

**Goal**: Reuse the existing external Secret and sensitive-token inputs without credential exposure.

**Independent Test**: Mock plans assert pre-defined Secret and sensitive token chart values, plus reject absent or ambiguous authentication.

- [x] T010 [US2] Implement the official chart Secret-reference and sensitive-token branches in `modules/github-actions-runner/main.tf`.
- [x] T011 [US2] Verify scale-set authentication success and failure assertions in `modules/github-actions-runner/tests/runner_modes.tftest.hcl`.

## Phase 5: User Story 3 - Preserve Legacy Consumers (Priority: P3)

**Goal**: Keep default legacy rendering and ensure normal upgrades move the Helm state address rather than replace it.

**Independent Test**: The existing legacy compatibility test passes with no scale-set inputs, and scale-set mode produces no legacy release or Runner manifests.

- [x] T012 [US3] Update legacy resource references and assertions for the moved Helm address in `modules/github-actions-runner/tests/runner_modes.tftest.hcl`.
- [x] T013 [US3] Verify legacy manifests remain gated to legacy mode in `modules/github-actions-runner/main.tf`.

## Phase 6: Documentation, Examples, and Validation

- [x] T014 [P] Add the generic external-Secret official scale-set example in `modules/github-actions-runner/examples/scale-set/0-setup.tf` and `modules/github-actions-runner/examples/scale-set/1-example.tf`.
- [x] T015 [P] Document the official-chart path, secret contract, queue-driven scaling, workflow `runs-on` migration, and legacy compatibility in `modules/github-actions-runner/README.md`.
- [x] T016 Regenerate the terraform-docs block in `modules/github-actions-runner/README.md` and verify it matches the final inputs and outputs.
- [x] T017 Run `terraform fmt -check -recursive`, `terraform init -backend=false`, `terraform validate`, and `terraform test` in `modules/github-actions-runner`.
- [x] T018 Run `terraform init -backend=false` and `terraform validate` in `modules/github-actions-runner/examples/scale-set`.
- [x] T019 Run available Checkov, tfsec, pre-commit, and tflint checks for `modules/github-actions-runner`; record unavailable tool limitations in `specs/019-github-scale-set/tasks.md`.
- [x] T020 Review all changed artifacts for secrets, customer-specific names, contract drift, Speckit completeness, and release readiness.

## Dependencies and Execution Order

- T001-T006 establish mode and state compatibility before either path is changed.
- T007-T009 implement and test the core scale-set capability.
- T010-T011 validate both authentication paths.
- T012-T013 confirm legacy behavior remains independent.
- T014-T020 finish documentation and validation after the interface is stable.

## Implementation Strategy

1. Add mode selection and tests without changing the legacy default.
2. Add the official chart pair and bounded values.
3. Prove credentials and legacy isolation with mock tests.
4. Add operator-facing example and migration documentation.
5. Run quality gates and open the PR for review.

## Verification Record

- `terraform fmt -check -recursive modules/github-actions-runner`: passed.
- Module `terraform init -backend=false`, `terraform validate`, and
  `terraform test`: passed; 13 tests and 0 failures.
- Scale-set example `terraform init -backend=false` and `terraform validate`:
  passed.
- `terraform-docs` regenerated the README block.
- Checkov and tfsec passed with no reported findings.
- `pre-commit` and `tflint` are unavailable locally; repository CI remains the
  enforcement point for those checks.

## Revised Standard Audit (2026-08-19)

- [x] T021 Re-audit `modules/github-actions-runner` against the revised module
  standard: verify independent example/test surfaces, native test discovery,
  Terraform 1.6+ compatibility, and ignored working files.
- [x] T022 Add local verification commands and accurate CI-signal status to
  `modules/github-actions-runner/README.md`.
- [x] T023 Record repository-level workflow and pre-commit baseline gaps in
  `specs/019-github-scale-set/plan.md` without expanding this module PR into an
  unrelated automation migration.
