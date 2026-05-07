# Tasks: Istio and Gateway API Upgrade Configurability

**Input**: Design documents from `/specs/004-upgrade-istio-gateway-api/`
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/module-interface.md`, `quickstart.md`

**Tests**: Tests are required for this feature because module behavior, defaults, and interface surface change.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Confirm scope and lock the implementation baseline for both modules.

- [x] T001 Capture current Istio and gateway-api-crds defaults in `modules/istio/README.md` and `modules/gateway-api-crds/README.md` as implementation baseline notes
- [x] T002 Identify in-scope example paths for validation in `modules/istio/examples/` and `modules/gateway-api-crds/examples/basic/`
- [x] T003 [P] Confirm automation entrypoints from `.pre-commit-config.yaml` and record required validation commands in `specs/004-upgrade-istio-gateway-api/quickstart.md`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Prepare shared version and schema groundwork that all user stories depend on.

**⚠️ CRITICAL**: No user story work starts before this phase is complete.

- [x] T004 Update planned version target notes and compatibility constraints in `specs/004-upgrade-istio-gateway-api/research.md`
- [x] T005 [P] Add/adjust shared input schema scaffolding for component image override objects in `modules/istio/variables.tf`
- [x] T006 [P] Prepare shared local/value derivation scaffolding for new Istio overrides in `modules/istio/main.tf`
- [x] T007 Confirm CRD version-contract baseline and expected `crdsList` mapping in `modules/gateway-api-crds/variables.tf`

**Checkpoint**: Foundation complete; user stories can proceed.

---

## Phase 3: User Story 1 - Configure per-component Istio images (Priority: P1) 🎯 MVP

**Goal**: Allow independent custom image repository/image for Istio `base`, `istiod`, and `gateway` while preserving current defaults.

**Independent Test**: Run plan against `modules/istio/examples/basic/1-example.tf` with and without per-component overrides and verify only targeted components change.

### Tests for User Story 1

- [x] T008 [P] [US1] Add override-usage validation scenario in `modules/istio/examples/basic/1-example.tf`
- [x] T009 [P] [US1] Add a component-specific override example in `modules/istio/examples/gateway-api-only/1-example.tf`

### Implementation for User Story 1

- [x] T010 [US1] Implement per-component image override input blocks and validation rules in `modules/istio/variables.tf`
- [x] T011 [US1] Wire per-component image override values into chart/resource rendering in `modules/istio/main.tf`
- [x] T012 [US1] Keep compatibility output behavior aligned with new inputs in `modules/istio/outputs.tf`
- [x] T013 [US1] Document new override interface and defaults in `modules/istio/README.md`
- [x] T014 [US1] Update related example usage for independent component override behavior in `modules/istio/examples/istiod-and-gateway-2-replicas/1-example.tf`

**Checkpoint**: US1 is independently functional and verifiable.

---

## Phase 4: User Story 2 - Upgrade Istio and Gateway API chart versions (Priority: P2)

**Goal**: Move default Istio/Gateway API chart versions to latest approved stable versions without breaking default consumer flow.

**Independent Test**: Execute plans for existing Istio example directories and confirm version-resolve/template-render success with new defaults.

### Tests for User Story 2

- [x] T015 [P] [US2] Validate default-path behavior using updated versions in `modules/istio/examples/basic/1-example.tf`
- [x] T016 [P] [US2] Validate gateway-api-focused behavior using updated versions in `modules/istio/examples/gateway-api-wildcard-tls-internal-and-external-and-restricted/1-example.tf`

### Implementation for User Story 2

- [x] T017 [US2] Update default chart versions for Istio components in `modules/istio/variables.tf`
- [x] T018 [US2] Update any version-wired logic and constraints in `modules/istio/main.tf`
- [x] T019 [US2] Review and adjust provider/version declarations if compatibility changes in `modules/istio/versions.tf`
- [x] T020 [US2] Document version baseline and migration notes in `modules/istio/README.md`

**Checkpoint**: US2 is independently functional and verifiable.

---

## Phase 5: User Story 3 - Upgrade and document Gateway API CRD lifecycle (Priority: P3)

**Goal**: Update gateway-api-crds to latest stable CRD contract, remove unused locals file, and document explicit CRD update workflow.

**Independent Test**: Follow documented upgrade process in `modules/gateway-api-crds/README.md` and verify selected CRDs match configured `version` and `crdsList`.

### Tests for User Story 3

- [x] T021 [P] [US3] Add/adjust CRD-version example assertions in `modules/gateway-api-crds/examples/basic/1-example.tf`
- [x] T022 [P] [US3] Verify CRD artifact list mapping against selected YAML in `modules/gateway-api-crds/files/v1.5.0-standard-install.yaml`

### Implementation for User Story 3

- [x] T023 [US3] Update CRD version and `crdsList` defaults in `modules/gateway-api-crds/variables.tf`
- [x] T024 [US3] Align CRD selection/rendering logic with updated contract in `modules/gateway-api-crds/main.tf`
- [x] T025 [US3] Remove unused locals file `modules/gateway-api-crds/locales.tf` and clean references in `modules/gateway-api-crds/main.tf`
- [x] T026 [US3] Update explicit CRD upgrade guidance (YAML, `version`, `crdsList`) in `modules/gateway-api-crds/README.md`
- [x] T027 [US3] Keep module outputs consistent after CRD contract updates in `modules/gateway-api-crds/outputs.tf`

**Checkpoint**: US3 is independently functional and verifiable.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final consistency, validation, and readiness checks across all stories.

- [x] T028 [P] Reconcile docs/examples consistency for touched modules in `modules/istio/README.md` and `modules/gateway-api-crds/README.md`
- [x] T029 Run formatting and docs generation hooks against changed paths using `.pre-commit-config.yaml`
- [x] T030 Run full feature validation across `modules/istio/examples/` and `modules/gateway-api-crds/examples/basic/`
- [x] T031 Capture downstream migration/compatibility summary in `specs/004-upgrade-istio-gateway-api/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: Starts immediately.
- **Phase 2 (Foundational)**: Depends on Phase 1 and blocks all user stories.
- **Phase 3 (US1)**: Depends on Phase 2.
- **Phase 4 (US2)**: Depends on Phase 2 (can run in parallel with US1 after foundation).
- **Phase 5 (US3)**: Depends on Phase 2 (can run in parallel with US1/US2 after foundation).
- **Phase 6 (Polish)**: Depends on completion of selected user stories.

### User Story Dependencies

- **US1 (P1)**: No dependency on US2/US3 after Phase 2.
- **US2 (P2)**: No strict dependency on US1; integrates with shared Istio files.
- **US3 (P3)**: Independent module path; no strict dependency on US1/US2 after Phase 2.

### Parallel Opportunities

- T003 can run with T001/T002.
- T005 and T006 can run in parallel.
- US1 test tasks T008/T009 can run in parallel.
- US2 test tasks T015/T016 can run in parallel.
- US3 test tasks T021/T022 can run in parallel.
- US2 and US3 implementation can proceed in parallel after Phase 2 if staffing allows.

---

## Parallel Example: User Story 3

```bash
# Parallel validation/design tasks:
Task: "Update CRD version defaults in modules/gateway-api-crds/variables.tf"
Task: "Update CRD upgrade documentation in modules/gateway-api-crds/README.md"

# Parallel checks:
Task: "Adjust example scenario in modules/gateway-api-crds/examples/basic/1-example.tf"
Task: "Verify YAML contract in modules/gateway-api-crds/files/v1.5.0-standard-install.yaml"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1 and Phase 2.
2. Deliver Phase 3 (US1) end-to-end.
3. Validate US1 independently as MVP.

### Incremental Delivery

1. Foundation (Phases 1-2).
2. US1 (MVP).
3. US2 version upgrades.
4. US3 CRD lifecycle/documentation updates.
5. Polish and full-path validation.

### Parallel Team Strategy

1. Team aligns on Phase 1-2 together.
2. Split by stories after foundation:
   - Engineer A: US1
   - Engineer B: US2
   - Engineer C: US3
3. Rejoin for Phase 6 cross-cutting validation.
