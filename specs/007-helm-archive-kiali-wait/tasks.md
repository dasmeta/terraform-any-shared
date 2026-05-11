# Tasks: Helm Archive Chart Sources and Kiali Apply Readiness

**Input**: Design documents from `/specs/007-helm-archive-kiali-wait/`
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/module-interface.md`, `quickstart.md`

**Tests**: Tests and validation are required because module behavior changes for Helm release arguments and Kiali custom resource apply behavior.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Capture the module-impacting change in Speckit before finalizing implementation.

- [x] T001 Identify affected module paths in `specs/007-helm-archive-kiali-wait/spec.md`
- [x] T002 Record internal standards, constitution source, and module-change gate evidence in `specs/007-helm-archive-kiali-wait/plan.md`
- [x] T003 [P] Create design artifacts in `specs/007-helm-archive-kiali-wait/research.md`, `specs/007-helm-archive-kiali-wait/data-model.md`, `specs/007-helm-archive-kiali-wait/contracts/module-interface.md`, and `specs/007-helm-archive-kiali-wait/quickstart.md`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Preserve compatibility and wrapper scope before story-specific changes.

**⚠️ CRITICAL**: No user story work should start before this phase completes.

- [x] T004 Confirm no new required inputs are needed in `modules/istio/variables.tf` or `modules/kiali/variables.tf`
- [x] T005 Confirm provider constraints do not need changes in `modules/istio/versions.tf` or `modules/kiali/versions.tf`
- [x] T006 Confirm direct chart archive support remains bounded to existing chart string fields and does not expose raw Helm provider pass-through settings

**Checkpoint**: Foundation complete; user story phases can proceed.

---

## Phase 3: User Story 1 - Use Direct Chart Archives For Istio (Priority: P1) 🎯 MVP

**Goal**: Allow Istio component and Gateway API resource chart fields to use direct HTTP(S) `.tgz` chart URLs.

**Independent Test**: Validate `modules/istio/examples/chart-direct-tgz-sources` with direct archive URLs for Istio base, istiod, optional gateway, and Gateway API resources.

### Tests and Validation for User Story 1

- [x] T007 [P] [US1] Add direct chart source example files under `modules/istio/examples/chart-direct-tgz-sources/`
- [ ] T008 [US1] Run `terraform validate` in `modules/istio/examples/chart-direct-tgz-sources`

### Implementation for User Story 1

- [x] T009 [US1] Add direct URL detection for Istio base, istiod, ingress gateways, and Gateway API resources in `modules/istio/main.tf`
- [x] T010 [US1] Update chart input descriptions in `modules/istio/variables.tf`
- [x] T011 [US1] Update `modules/istio/README.md` or generated docs to mention direct HTTP(S) chart archive URL behavior

**Checkpoint**: US1 is independently functional and verifiable.

---

## Phase 4: User Story 2 - Use Direct Chart Archives For Kiali Operator (Priority: P2)

**Goal**: Allow standalone and Istio-delegated Kiali operator chart fields to use direct HTTP(S) `.tgz` chart URLs.

**Independent Test**: Validate Kiali standalone or Istio delegated Kiali example with `configs.operator.chart` or `configs.kiali.operator.chart` set to an HTTP(S) chart archive URL.

### Tests and Validation for User Story 2

- [ ] T012 [US2] Run `terraform validate` in `modules/kiali/examples/basic`
- [ ] T013 [US2] Run `terraform validate` in `modules/istio/examples/kiali-observability` or the archive-backed Istio example with Kiali enabled

### Implementation for User Story 2

- [x] T014 [US2] Add direct URL detection for the Kiali operator chart in `modules/kiali/main.tf`
- [x] T015 [US2] Update chart input descriptions in `modules/kiali/variables.tf`
- [x] T016 [US2] Update `modules/kiali/README.md` or generated docs to mention direct HTTP(S) chart archive URL behavior

**Checkpoint**: US2 is independently functional and verifiable.

---

## Phase 5: User Story 3 - Wait For Kiali Custom Resource Creation (Priority: P3)

**Goal**: Ensure enabled Kiali custom resource creation waits for readiness.

**Independent Test**: Review or plan `modules/kiali` and confirm `kubectl_manifest.this` contains `wait = true`.

### Tests and Validation for User Story 3

- [x] T017 [US3] Confirm `kubectl_manifest.this` includes `wait = true` in `modules/kiali/main.tf`
- [ ] T018 [US3] Validate a Kiali-enabled example path after provider initialization is available

### Implementation for User Story 3

- [x] T019 [US3] Set `wait = true` on the Kiali custom resource in `modules/kiali/main.tf`
- [x] T020 [US3] Document apply-readiness behavior in `modules/kiali/README.md`

**Checkpoint**: US3 is independently functional and verifiable.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final consistency, validation, and readiness checks across all stories.

- [x] T021 Remove registry-specific derivation and normalize the direct chart source example in `modules/istio/examples/chart-direct-tgz-sources/`
- [x] T022 Confirm ignored Terraform runtime artifacts in `modules/istio/examples/chart-direct-tgz-sources/` are not staged
- [x] T023 Run `terraform fmt -check -recursive modules/istio modules/kiali`
- [x] T024 Run Speckit prerequisite check with `SPECIFY_FEATURE=007-helm-archive-kiali-wait .specify/scripts/bash/check-prerequisites.sh --json --require-tasks --include-tasks`
- [x] T025 Review final diff for wrapper drift, unrelated module changes, and missing validation evidence

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: Starts immediately.
- **Phase 2 (Foundational)**: Depends on Phase 1 and blocks all user stories.
- **Phase 3 (US1)**: Depends on Phase 2.
- **Phase 4 (US2)**: Depends on Phase 2.
- **Phase 5 (US3)**: Depends on Phase 2.
- **Phase 6 (Polish)**: Depends on selected user stories.

### User Story Dependencies

- **US1 (P1)**: No dependency on US2/US3 after Phase 2.
- **US2 (P2)**: No dependency on US1 after Phase 2, but the archive-backed Istio example can validate both US1 and US2 together when Kiali is enabled.
- **US3 (P3)**: Depends only on the existing Kiali CR resource path.

### Parallel Opportunities

- T003 can run in parallel with T001/T002.
- T007 can run in parallel with T009/T010 if files are owned by different contributors.
- T012 and T013 can run in parallel after Kiali URL support is implemented.
- T021 and T022 can run while formatting checks are prepared.

---

## Implementation Strategy

### MVP First (US1 Only)

1. Complete Phase 1 and Phase 2.
2. Deliver Phase 3 so direct Istio and Gateway API chart archives work.
3. Validate the archive-backed Istio example.

### Incremental Delivery

1. Deliver US1 for Istio archive charts.
2. Deliver US2 for Kiali operator archive charts.
3. Deliver US3 for Kiali CR readiness.
4. Finish Phase 6 validation and docs consistency checks.
