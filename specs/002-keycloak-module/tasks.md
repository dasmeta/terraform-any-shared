---

description: "Task list for Keycloak Helm wrapper module"
---

# Tasks: Keycloak Helm Wrapper Module

**Input**: Design documents from `/specs/002-keycloak-module/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Test tasks are included because the specification explicitly
requires at least one example path, at least one test path, and validation for
the new maintained module behavior.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Terraform module**: `modules/keycloak/`
- **Examples**: `modules/keycloak/examples/basic/`
- **Tests**: `modules/keycloak/tests/basic/`
- **Automation**: `.github/workflows/`, `.pre-commit-config.yaml`

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create the new module workspace and identify the repo-level
validation touchpoints it must join

- [X] T001 Create the Keycloak module file skeleton in `modules/keycloak/main.tf`, `modules/keycloak/variables.tf`, `modules/keycloak/outputs.tf`, `modules/keycloak/versions.tf`, and `modules/keycloak/README.md`
- [X] T002 Create the support-artifact skeleton in `modules/keycloak/examples/basic/0-setup.tf`, `modules/keycloak/examples/basic/README.md`, `modules/keycloak/tests/basic/providers.tf`, `modules/keycloak/tests/basic/main.tf`, and `modules/keycloak/tests/basic/README.md`
- [X] T003 [P] Capture the maintained-module validation touchpoints for `modules/keycloak` in `.github/workflows/checkov.yaml`, `.github/workflows/tflint.yaml`, `.github/workflows/terraform-test.yaml`, and `.pre-commit-config.yaml`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Establish the shared compatibility baseline and curated interface
shape that all user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T004 Define Terraform and provider compatibility for the module in `modules/keycloak/versions.tf`
- [X] T005 [P] Define the shared curated inputs and validation rules for release identity, external database, ingress, and bootstrap credentials in `modules/keycloak/variables.tf`
- [X] T006 [P] Establish the shared Helm values assembly and secret-source selection scaffolding in `modules/keycloak/main.tf`
- [X] T007 Establish the stable output names and placeholder output wiring in `modules/keycloak/outputs.tf`

**Checkpoint**: Foundation ready - user story work can now proceed in priority order

---

## Phase 3: User Story 1 - Deploy a Standard Keycloak Release (Priority: P1) 🎯 MVP

**Goal**: Deliver one supported baseline Keycloak deployment path that matches
the repository’s Helm-wrapper style

**Independent Test**: Run the documented basic example from
`modules/keycloak/examples/basic/` and confirm it represents one complete
supported external-database Keycloak release without raw chart pass-through

### Tests for User Story 1

- [X] T008 [P] [US1] Add the baseline example consumer configuration in `modules/keycloak/examples/basic/1-example.tf`
- [X] T009 [P] [US1] Add baseline Terraform validation coverage for the standard release path in `modules/keycloak/tests/basic/main.tf`

### Implementation for User Story 1

- [X] T010 [US1] Implement the standard external-database Keycloak Helm release path in `modules/keycloak/main.tf`
- [X] T011 [P] [US1] Finalize the baseline release outputs in `modules/keycloak/outputs.tf`
- [X] T012 [US1] Document baseline prerequisites, defaults, and supported usage in `modules/keycloak/README.md` and `modules/keycloak/examples/basic/README.md`
- [X] T013 [US1] Run baseline validation for `modules/keycloak/`, `modules/keycloak/examples/basic/`, and `modules/keycloak/tests/basic/`

**Checkpoint**: User Story 1 should now deliver a reviewable MVP module path

---

## Phase 4: User Story 2 - Customize the Common Keycloak Use Case (Priority: P2)

**Goal**: Extend the baseline module with the common customization knobs teams
actually need while preserving the curated wrapper boundary

**Independent Test**: Review and validate the module interface, example, and
test path to confirm hostname, ingress, external-database, and
bootstrap-credential customization are supported without exposing the full
upstream chart surface

### Tests for User Story 2

- [X] T014 [P] [US2] Extend the example and test inputs for hostname, ingress, and bootstrap credential mode selection in `modules/keycloak/examples/basic/1-example.tf` and `modules/keycloak/tests/basic/main.tf`

### Implementation for User Story 2

- [X] T015 [P] [US2] Implement curated customization inputs and conflict validation for ingress and bootstrap credential modes in `modules/keycloak/variables.tf`
- [X] T016 [US2] Implement common-case override wiring for ingress, external database settings, and bootstrap secret source selection in `modules/keycloak/main.tf`
- [X] T017 [US2] Update release outputs and consumer guidance for customization boundaries in `modules/keycloak/outputs.tf` and `modules/keycloak/README.md`
- [X] T018 [US2] Re-run validation for the customization path in `modules/keycloak/`, `modules/keycloak/examples/basic/`, and `modules/keycloak/tests/basic/`

**Checkpoint**: User Stories 1 and 2 should now be independently reviewable with a stable curated interface

---

## Phase 5: User Story 3 - Trust the Module Through Documentation and Validation (Priority: P3)

**Goal**: Make the new module reviewable and adoptable as a maintained module
through aligned docs, support artifacts, and workflow coverage

**Independent Test**: Review `modules/keycloak/README.md`,
`modules/keycloak/examples/basic/`, `modules/keycloak/tests/basic/`, and the
workflow files to confirm the module is documented consistently and included in
the maintained-module quality gates

### Tests for User Story 3

- [X] T019 [P] [US3] Finalize reviewable support guidance in `modules/keycloak/examples/basic/README.md` and `modules/keycloak/tests/basic/README.md`

### Implementation for User Story 3

- [X] T020 [P] [US3] Add `modules/keycloak` to the maintained-module matrix in `.github/workflows/checkov.yaml`
- [X] T021 [P] [US3] Add `modules/keycloak` to the maintained-module matrices in `.github/workflows/tflint.yaml` and `.github/workflows/terraform-test.yaml`
- [X] T022 [US3] Reconcile terraform-docs and formatting expectations for `modules/keycloak/README.md` under `.pre-commit-config.yaml`
- [X] T023 [US3] Finalize maintainer-facing documentation alignment in `modules/keycloak/README.md`, `modules/keycloak/examples/basic/README.md`, and `modules/keycloak/tests/basic/README.md`
- [X] T024 [US3] Validate maintained-module coverage and support-artifact alignment in `.github/workflows/checkov.yaml`, `.github/workflows/tflint.yaml`, `.github/workflows/terraform-test.yaml`, `modules/keycloak/README.md`, `modules/keycloak/examples/basic/README.md`, and `modules/keycloak/tests/basic/README.md`

**Checkpoint**: All user stories should now be independently reviewable and the module should satisfy the maintained-module delivery bar

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final consistency review and full-feature verification

- [X] T025 [P] Reconcile all touched module files in `modules/keycloak/main.tf`, `modules/keycloak/variables.tf`, `modules/keycloak/outputs.tf`, `modules/keycloak/versions.tf`, and `modules/keycloak/README.md`
- [X] T026 [P] Reconcile all touched support assets in `modules/keycloak/examples/basic/`, `modules/keycloak/tests/basic/`, and `.github/workflows/`
- [X] T027 Re-run the full validation commands documented in `specs/002-keycloak-module/quickstart.md`
- [X] T028 Review the final diff in `modules/keycloak/`, `.github/workflows/`, `.pre-commit-config.yaml`, and `specs/002-keycloak-module/` for wrapper drift, unsupported pass-through exposure, and stale documentation

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - blocks all user stories
- **User Story 1 (Phase 3)**: Depends on Foundational completion
- **User Story 2 (Phase 4)**: Depends on User Story 1 establishing the baseline module path
- **User Story 3 (Phase 5)**: Depends on User Stories 1 and 2 so docs and workflow coverage reflect the final supported interface
- **Polish (Phase 6)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: First deliverable and recommended MVP scope
- **User Story 2 (P2)**: Extends the baseline from User Story 1 with supported common customizations
- **User Story 3 (P3)**: Finalizes maintainability, documentation, and workflow inclusion after the interface is stable

### Within Each User Story

- Example/test updates before or alongside implementation
- Variable validation before final resource wiring
- Core Terraform implementation before final documentation sync
- Story-specific validation before moving to the next phase

### Parallel Opportunities

- `T003` can run in parallel with `T001` and `T002`
- `T005` and `T006` can run in parallel once the module skeleton exists
- `T008` and `T009` can run in parallel within User Story 1
- `T011` can run in parallel with `T012` after `T010` stabilizes the baseline release shape
- `T014` and `T015` can run in parallel within User Story 2
- `T020` and `T021` can run in parallel within User Story 3
- `T025` and `T026` can run in parallel before the final validation pass

---

## Parallel Example: User Story 1

```bash
# Launch the baseline example and test tasks together:
Task: "Add the baseline example consumer configuration in modules/keycloak/examples/basic/1-example.tf"
Task: "Add baseline Terraform validation coverage for the standard release path in modules/keycloak/tests/basic/main.tf"
```

---

## Parallel Example: User Story 2

```bash
# Launch disjoint customization tasks together:
Task: "Extend the example and test inputs for hostname, ingress, and bootstrap credential mode selection in modules/keycloak/examples/basic/1-example.tf and modules/keycloak/tests/basic/main.tf"
Task: "Implement curated customization inputs and conflict validation for ingress and bootstrap credential modes in modules/keycloak/variables.tf"
```

---

## Parallel Example: User Story 3

```bash
# Launch independent workflow updates together:
Task: "Add modules/keycloak to the maintained-module matrix in .github/workflows/checkov.yaml"
Task: "Add modules/keycloak to the maintained-module matrices in .github/workflows/tflint.yaml and .github/workflows/terraform-test.yaml"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete Phase 3: User Story 1
4. Stop and validate the baseline Keycloak deployment path

### Incremental Delivery

1. Complete Setup + Foundational
2. Deliver User Story 1 for the first supported Keycloak release path
3. Deliver User Story 2 for common-case customization without interface drift
4. Deliver User Story 3 for maintained-module reviewability and workflow coverage
5. Finish with Polish and the full validation pass

### Parallel Team Strategy

1. One contributor establishes the shared module skeleton and compatibility baseline
2. After Foundational completes:
   - Contributor A handles the baseline module implementation and outputs for User Story 1
   - Contributor B prepares customization-facing example/test inputs and variable validation for User Story 2
   - Contributor C prepares workflow coverage updates and support-asset guidance for User Story 3 once the interface stabilizes
3. Merge at the Polish phase for full validation and wrapper-boundary review

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] labels map every story-phase task to the corresponding user story
- Every user story has an explicit independent test criterion
- The suggested MVP scope is User Story 1 only
- Do not add generic Helm values pass-through or undocumented advanced chart options during implementation
