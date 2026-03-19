---

description: "Task list for repository module housekeeping"
---

# Tasks: Repository Module Housekeeping

**Input**: Design documents from `/specs/001-standardize-module-housekeeping/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: No dedicated test-authoring tasks are generated because the specification limits this feature to housekeeping and validation/documentation alignment rather than behavior changes. Validation execution tasks are still included.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Terraform module**: `modules/<module-name>/`
- **Examples**: `modules/<module-name>/examples/<scenario>/`
- **Tests**: `modules/<module-name>/tests/<scenario>/` or Terraform example assertions adjacent to the example when that is the established pattern
- **Automation**: `.github/workflows/`, `.pre-commit-config.yaml`
- **Housekeeping docs**: `docs/module-housekeeping/`

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create the persistent housekeeping workspace and capture the current repository baseline

- [X] T001 Create the housekeeping workspace in `docs/module-housekeeping/README.md`, `docs/module-housekeeping/module-baseline.md`, `docs/module-housekeeping/maintained-modules.md`, `docs/module-housekeeping/exceptions.md`, and `docs/module-housekeeping/validation-coverage.md`
- [X] T002 Capture the current top-level module inventory from `modules/` in `docs/module-housekeeping/maintained-modules.md`
- [X] T003 [P] Capture the current automation inventory from `.github/workflows/checkov.yaml`, `.github/workflows/tflint.yaml`, `.github/workflows/terraform-test.yaml`, `.github/workflows/pre-commit.yaml`, `.github/workflows/tfsec.yaml`, and `.pre-commit-config.yaml` in `docs/module-housekeeping/validation-coverage.md`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Establish the baseline rules and exception model that all user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T004 Define the maintained-module baseline, required support artifacts, and naming rules in `docs/module-housekeeping/module-baseline.md`
- [X] T005 [P] Classify `modules/k8s/`, `modules/keeper-reader/modules/`, and `modules/onepassword/module/get-data/` in `docs/module-housekeeping/maintained-modules.md`
- [X] T006 [P] Record approval-gated rename and structure conflicts for `modules/service/deploy.tf`, `modules/gateway-api-crds/locales.tf`, `modules/kyverno/locales.tf`, and `modules/gitlab-runner/config.tf` in `docs/module-housekeeping/exceptions.md`
- [X] T007 Reconcile the current workflow-to-module mapping in `docs/module-housekeeping/validation-coverage.md` using `.github/workflows/checkov.yaml`, `.github/workflows/tflint.yaml`, `.github/workflows/terraform-test.yaml`, `.github/workflows/pre-commit.yaml`, and `.github/workflows/tfsec.yaml`

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Standardize Module Housekeeping Baseline (Priority: P1) 🎯 MVP

**Goal**: Bring maintained modules to a consistent documented baseline for structure and support artifacts without changing behavior

**Independent Test**: Review `docs/module-housekeeping/maintained-modules.md` and confirm every maintained module is marked aligned, follow-up-required, or excepted, with safe structural fixes applied where no approval gate is triggered

### Implementation for User Story 1

- [X] T008 [P] [US1] Normalize provider and version file names for `modules/github-actions-runner/provider.tf`, `modules/keeper-reader/provider.tf`, `modules/loki/version.tf`, and `modules/qdrant/version.tf`
- [X] T009 [P] [US1] Correct the housekeeping typo in `modules/goldilocks/varables.tf`
- [X] T010 [P] [US1] Normalize the singular example directory from `modules/onepassword_to_secret_manager/example/` to `modules/onepassword_to_secret_manager/examples/basic/`
- [X] T011 [US1] Record missing `examples/` support decisions for `modules/github-actions-runner/`, `modules/goldilocks/`, `modules/kafka/`, `modules/minio/`, `modules/mongodb/`, `modules/mongodb-bi-connector/`, `modules/qdrant/`, and `modules/supabase/` in `docs/module-housekeeping/maintained-modules.md`
- [X] T012 [US1] Record missing `tests/` support decisions and justified exceptions for maintained modules in `docs/module-housekeeping/exceptions.md`
- [X] T013 [US1] Update final alignment status and artifact coverage for all maintained modules in `docs/module-housekeeping/maintained-modules.md`

**Checkpoint**: At this point, User Story 1 should be independently reviewable as a complete housekeeping-baseline increment

---

## Phase 4: User Story 2 - Expand Validation Confidence (Priority: P2)

**Goal**: Align repository validation scope with the maintained-module inventory and document all exclusions

**Independent Test**: Compare `docs/module-housekeeping/validation-coverage.md` against the workflow files and confirm every maintained module has either explicit automated coverage or a documented exclusion

### Implementation for User Story 2

- [X] T014 [US2] Update maintained-module coverage in `.github/workflows/checkov.yaml`
- [X] T015 [P] [US2] Update maintained-module coverage in `.github/workflows/tflint.yaml`
- [X] T016 [P] [US2] Update maintained-module coverage in `.github/workflows/terraform-test.yaml`
- [X] T017 [US2] Repair matrix handling and maintained-module scope in `.github/workflows/pre-commit.yaml`
- [X] T018 [US2] Align repo-wide formatting and terraform-docs expectations in `.pre-commit-config.yaml`
- [X] T019 [US2] Reconcile final validation coverage, partial coverage, and documented exclusions in `docs/module-housekeeping/validation-coverage.md`

**Checkpoint**: At this point, User Stories 1 and 2 should both be independently reviewable

---

## Phase 5: User Story 3 - Improve Consumer Trust in Module Docs (Priority: P3)

**Goal**: Make maintained module documentation and support guidance consistently understandable to consumers

**Independent Test**: Open representative maintained module documentation and confirm a consumer can find module purpose, support artifacts, and validation context without reading source internals

### Implementation for User Story 3

- [X] T020 [P] [US3] Add or normalize human-written README preambles in `modules/defectdojo/README.md`, `modules/event-exporter/README.md`, `modules/gateway-api-crds/README.md`, `modules/github-actions-runner/README.md`, `modules/goldilocks/README.md`, `modules/kafka/README.md`, and `modules/minio/README.md`
- [X] T021 [P] [US3] Add or normalize human-written README preambles in `modules/mongodb/README.md`, `modules/onepassword/README.md`, `modules/onepassword_to_secret_manager/README.md`, `modules/service/README.md`, `modules/supabase/README.md`, `modules/keeper-reader/README.md`, and `modules/sentry/README.md`
- [X] T022 [P] [US3] Normalize consumer guidance in `modules/event-exporter/examples/README.md`, `modules/onepassword/examples/README.md`, `modules/qdrant/tests/basic/README.md`, and `modules/mongodb-bi-connector/tests/basic/README.md`
- [X] T023 [US3] Create the repository-level module housekeeping overview in `README.md`
- [X] T024 [US3] Update final consumer-facing support expectations and links in `docs/module-housekeeping/README.md` and `docs/module-housekeeping/module-baseline.md`

**Checkpoint**: All user stories should now be independently reviewable

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final consistency, verification, and handoff work across the whole feature

- [X] T025 [P] Reconcile all touched housekeeping docs in `docs/module-housekeeping/README.md`, `docs/module-housekeeping/module-baseline.md`, `docs/module-housekeeping/maintained-modules.md`, `docs/module-housekeeping/exceptions.md`, and `docs/module-housekeeping/validation-coverage.md`
- [X] T026 Re-run repository validation commands from `specs/001-standardize-module-housekeeping/quickstart.md`
- [X] T027 Review diffs under `modules/`, `.github/workflows/`, `.pre-commit-config.yaml`, and `README.md` to confirm no runtime behavior or interface changes were introduced
- [X] T028 Update verification or exception-handling guidance in `specs/001-standardize-module-housekeeping/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - blocks all user stories
- **User Story 1 (Phase 3)**: Depends on Foundational completion
- **User Story 2 (Phase 4)**: Depends on Foundational completion and should reuse the maintained-module inventory from User Story 1
- **User Story 3 (Phase 5)**: Depends on Foundational completion and should reuse the baseline/exception decisions from User Story 1
- **Polish (Phase 6)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Starts first after Foundational because it defines the maintained-module baseline and structural exceptions
- **User Story 2 (P2)**: Depends on the maintained inventory from User Story 1 to decide workflow scope and exclusions
- **User Story 3 (P3)**: Depends on the maintained inventory and exception model from User Story 1, but not on workflow edits from User Story 2

### Within Each User Story

- Safe structural normalization before final inventory status
- Workflow edits before final validation coverage reconciliation
- Module README edits before repository-level overview updates
- Story checkpoint review before moving to the next priority

### Parallel Opportunities

- `T003`, `T005`, and `T006` can run in parallel once `T001` and `T002` exist
- `T008`, `T009`, and `T010` can run in parallel within User Story 1
- `T015` and `T016` can run in parallel within User Story 2
- `T020`, `T021`, and `T022` can run in parallel within User Story 3
- `T025` can run in parallel with preparation for `T026`, but `T027` depends on validation output

---

## Parallel Example: User Story 1

```bash
# Launch safe file normalization tasks together:
Task: "Normalize provider and version file names for modules/github-actions-runner/provider.tf, modules/keeper-reader/provider.tf, modules/loki/version.tf, and modules/qdrant/version.tf"
Task: "Correct the housekeeping typo in modules/goldilocks/varables.tf"
Task: "Normalize the singular example directory from modules/onepassword_to_secret_manager/example/ to modules/onepassword_to_secret_manager/examples/basic/"
```

## Parallel Example: User Story 2

```bash
# Launch independent workflow updates together:
Task: "Update maintained-module coverage in .github/workflows/tflint.yaml"
Task: "Update maintained-module coverage in .github/workflows/terraform-test.yaml"
```

## Parallel Example: User Story 3

```bash
# Launch disjoint documentation batches together:
Task: "Add or normalize human-written README preambles in modules/defectdojo/README.md, modules/event-exporter/README.md, modules/gateway-api-crds/README.md, modules/github-actions-runner/README.md, modules/goldilocks/README.md, modules/kafka/README.md, and modules/minio/README.md"
Task: "Add or normalize human-written README preambles in modules/mongodb/README.md, modules/onepassword/README.md, modules/onepassword_to_secret_manager/README.md, modules/service/README.md, modules/supabase/README.md, modules/keeper-reader/README.md, and modules/sentry/README.md"
Task: "Normalize consumer guidance in modules/event-exporter/examples/README.md, modules/onepassword/examples/README.md, modules/qdrant/tests/basic/README.md, and modules/mongodb-bi-connector/tests/basic/README.md"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete Phase 3: User Story 1
4. Stop and validate the maintained-module inventory and exception model

### Incremental Delivery

1. Complete Setup + Foundational
2. Deliver User Story 1 to define the baseline and structural inventory
3. Deliver User Story 2 to align validation coverage with the inventory
4. Deliver User Story 3 to normalize consumer-facing documentation
5. Finish with Polish and repository-wide verification

### Parallel Team Strategy

1. One contributor establishes the docs baseline in `docs/module-housekeeping/`
2. After Foundational is complete:
   - Contributor A handles safe structural normalization for User Story 1
   - Contributor B handles workflow coverage for User Story 2
   - Contributor C handles README/example/test guidance for User Story 3
3. Merge at the Polish phase for validation and no-behavior-change review

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to a specific user story for traceability
- Every user story has an explicit independent test criterion
- Dedicated test-authoring tasks are intentionally omitted because the feature is housekeeping-only and the spec does not request TDD
- Avoid undocumented structural renames when they could create an approval-gated standards conflict
