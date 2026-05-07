# Tasks: Kiali Observability For Istio

**Input**: Design documents from `/Users/tmuradyan/projects/dasmeta/terraform-any-shared/specs/006-kiali-observability/`
**Prerequisites**: `plan.md` (required), `spec.md` (required), `research.md`, `data-model.md`, `contracts/module-interface.md`, `quickstart.md`

**Tests**: Include validation tasks because module behavior and consumer interface changed.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing.

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Confirm scope, baseline, and validation command set for `modules/kiali` and `modules/istio`.

- [x] T001 Confirm feature scope and in-scope files using `/Users/tmuradyan/projects/dasmeta/terraform-any-shared/specs/006-kiali-observability/plan.md`
- [x] T002 Capture current interface baseline in `/Users/tmuradyan/projects/dasmeta/terraform-any-shared/modules/kiali/variables.tf` and `/Users/tmuradyan/projects/dasmeta/terraform-any-shared/modules/istio/variables.tf`
- [x] T003 [P] Confirm validation command list in `/Users/tmuradyan/projects/dasmeta/terraform-any-shared/specs/006-kiali-observability/quickstart.md` and `/Users/tmuradyan/projects/dasmeta/terraform-any-shared/.pre-commit-config.yaml`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Complete shared plumbing required by all user stories before story-specific work.

**⚠️ CRITICAL**: No user story work should start before this phase completes.

- [x] T004 Finalize Kiali wrapper input schema in `/Users/tmuradyan/projects/dasmeta/terraform-any-shared/modules/kiali/variables.tf`
- [x] T005 [P] Finalize Kiali CR composition locals in `/Users/tmuradyan/projects/dasmeta/terraform-any-shared/modules/kiali/locals.tf`
- [x] T006 [P] Finalize Kiali operator and CR resource wiring in `/Users/tmuradyan/projects/dasmeta/terraform-any-shared/modules/kiali/main.tf`
- [x] T007 Finalize optional Istio delegation entrypoint in `/Users/tmuradyan/projects/dasmeta/terraform-any-shared/modules/istio/main.tf`
- [x] T008 Finalize Istio-side Kiali delegation inputs in `/Users/tmuradyan/projects/dasmeta/terraform-any-shared/modules/istio/variables.tf`

**Checkpoint**: Foundation complete - user story phases can proceed.

---

## Phase 3: User Story 1 - Deploy Kiali With Istio (Priority: P1) 🎯 MVP

**Goal**: Enable standalone Kiali deployment and optional Istio delegation with no default behavior regression.

**Independent Test**: Run plan/validate for Kiali standalone and Istio Kiali example to confirm operator release and Kiali CR render.

### Tests and Validation for User Story 1

- [x] T009 [P] [US1] Add or update standalone Kiali example assertion scaffolding in `/Users/tmuradyan/projects/dasmeta/terraform-any-shared/modules/kiali/examples/basic/0-setup.tf`
- [x] T010 [P] [US1] Add or update standalone Kiali usage example in `/Users/tmuradyan/projects/dasmeta/terraform-any-shared/modules/kiali/examples/basic/1-example.tf`

### Implementation for User Story 1

- [x] T011 [US1] Finalize Kiali outputs contract in `/Users/tmuradyan/projects/dasmeta/terraform-any-shared/modules/kiali/outputs.tf`
- [x] T012 [US1] Finalize Istio delegated Kiali outputs in `/Users/tmuradyan/projects/dasmeta/terraform-any-shared/modules/istio/outputs.tf`
- [x] T013 [US1] Align Istio delegated Kiali example in `/Users/tmuradyan/projects/dasmeta/terraform-any-shared/modules/istio/examples/kiali-observability/1-example.tf`
- [x] T014 [US1] Document standalone and delegated Kiali flow in `/Users/tmuradyan/projects/dasmeta/terraform-any-shared/modules/kiali/README.md` and `/Users/tmuradyan/projects/dasmeta/terraform-any-shared/modules/istio/README.md`
- [x] T015 [US1] Validate US1 flows with `terraform init && terraform validate` in `/Users/tmuradyan/projects/dasmeta/terraform-any-shared/modules/kiali/examples/basic` and `/Users/tmuradyan/projects/dasmeta/terraform-any-shared/modules/istio/examples/kiali-observability`

**Checkpoint**: US1 delivers MVP behavior and remains independently testable.

---

## Phase 4: User Story 2 - Connect Kiali To Prometheus (Priority: P2)

**Goal**: Support Prometheus external service configuration for Kiali through wrapper inputs and Istio delegation.

**Independent Test**: Configure `configs.kiali.cr.external_services.prometheus.url` in example and confirm rendered Kiali CR contains Prometheus settings.

### Tests and Validation for User Story 2

- [x] T016 [P] [US2] Add Prometheus-focused example values in `/Users/tmuradyan/projects/dasmeta/terraform-any-shared/modules/istio/examples/kiali-observability/1-example.tf`
- [x] T017 [P] [US2] Add Prometheus-focused standalone example values in `/Users/tmuradyan/projects/dasmeta/terraform-any-shared/modules/kiali/examples/basic/1-example.tf`

### Implementation for User Story 2

- [x] T018 [US2] Finalize Prometheus field mapping and merge behavior in `/Users/tmuradyan/projects/dasmeta/terraform-any-shared/modules/kiali/locals.tf`
- [x] T019 [US2] Finalize Prometheus-related input descriptions in `/Users/tmuradyan/projects/dasmeta/terraform-any-shared/modules/kiali/variables.tf` and `/Users/tmuradyan/projects/dasmeta/terraform-any-shared/modules/istio/variables.tf`
- [x] T020 [US2] Document Prometheus integration usage in `/Users/tmuradyan/projects/dasmeta/terraform-any-shared/modules/kiali/README.md` and `/Users/tmuradyan/projects/dasmeta/terraform-any-shared/modules/istio/README.md`
- [x] T021 [US2] Validate US2 flow with `terraform validate` in `/Users/tmuradyan/projects/dasmeta/terraform-any-shared/modules/kiali/examples/basic` and `/Users/tmuradyan/projects/dasmeta/terraform-any-shared/modules/istio/examples/kiali-observability`

**Checkpoint**: US2 Prometheus integration works independently.

---

## Phase 5: User Story 3 - Connect Kiali To Grafana (Priority: P3)

**Goal**: Support Grafana integration fields and include Kiali in custom chart/image override example.

**Independent Test**: Configure Grafana settings and verify rendered Kiali CR includes `external_services.grafana`; confirm `custom-chart-and-image-overrides` includes `configs.kiali` usage.

### Tests and Validation for User Story 3

- [x] T022 [P] [US3] Add Grafana-focused values to `/Users/tmuradyan/projects/dasmeta/terraform-any-shared/modules/istio/examples/kiali-observability/1-example.tf`
- [x] T023 [P] [US3] Add `configs.kiali` usage to `/Users/tmuradyan/projects/dasmeta/terraform-any-shared/modules/istio/examples/custom-chart-and-image-overrides/1-example.tf`

### Implementation for User Story 3

- [x] T024 [US3] Finalize Grafana field mapping and merge behavior in `/Users/tmuradyan/projects/dasmeta/terraform-any-shared/modules/kiali/locals.tf`
- [x] T025 [US3] Finalize Kiali server image override behavior (including ad-hoc allowance) in `/Users/tmuradyan/projects/dasmeta/terraform-any-shared/modules/istio/main.tf`
- [x] T026 [US3] Update Grafana and custom-overrides documentation in `/Users/tmuradyan/projects/dasmeta/terraform-any-shared/modules/kiali/README.md` and `/Users/tmuradyan/projects/dasmeta/terraform-any-shared/modules/istio/README.md`
- [x] T027 [US3] Validate US3 flow with `terraform validate` in `/Users/tmuradyan/projects/dasmeta/terraform-any-shared/modules/istio/examples/custom-chart-and-image-overrides` and `/Users/tmuradyan/projects/dasmeta/terraform-any-shared/modules/istio/examples/kiali-observability`

**Checkpoint**: US3 Grafana + integrated custom-overrides story is independently testable.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final repo-level consistency, formatting, and governance checks.

- [x] T028 [P] Run `terraform fmt -recursive` for `/Users/tmuradyan/projects/dasmeta/terraform-any-shared/modules/kiali` and `/Users/tmuradyan/projects/dasmeta/terraform-any-shared/modules/istio`
- [x] T029 Run `pre-commit run terraform_fmt --all-files` in `/Users/tmuradyan/projects/dasmeta/terraform-any-shared`
- [x] T030 Run `pre-commit run terraform_docs --all-files` in `/Users/tmuradyan/projects/dasmeta/terraform-any-shared`
- [x] T031 Review wrapper/interface drift and migration impact in `/Users/tmuradyan/projects/dasmeta/terraform-any-shared/modules/kiali/README.md`, `/Users/tmuradyan/projects/dasmeta/terraform-any-shared/modules/istio/README.md`, and `/Users/tmuradyan/projects/dasmeta/terraform-any-shared/specs/006-kiali-observability/plan.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: starts immediately.
- **Phase 2 (Foundational)**: depends on Phase 1; blocks all user stories.
- **Phase 3 (US1)**: depends on Phase 2; MVP baseline for feature.
- **Phase 4 (US2)**: depends on Phase 2; can run after or in parallel with US1 when staffing allows.
- **Phase 5 (US3)**: depends on Phase 2; can run after or in parallel with US2 when staffing allows.
- **Phase 6 (Polish)**: depends on completion of selected user stories.

### User Story Dependencies

- **US1 (P1)**: no dependency on US2/US3; establishes deploy + delegation baseline.
- **US2 (P2)**: depends on foundational plumbing but remains independently testable.
- **US3 (P3)**: depends on foundational plumbing but remains independently testable.

### Parallel Opportunities

- Phase 1: `T003` can run in parallel with `T001-T002`.
- Phase 2: `T005` and `T006` can run in parallel after `T004`.
- US1: `T009` and `T010` can run in parallel.
- US2: `T016` and `T017` can run in parallel.
- US3: `T022` and `T023` can run in parallel.
- Polish: `T028` can run before pre-commit tasks while docs review proceeds separately.

---

## Parallel Example: User Story 3

```bash
# Parallelize example updates:
Task: "Update /Users/tmuradyan/projects/dasmeta/terraform-any-shared/modules/istio/examples/kiali-observability/1-example.tf"
Task: "Update /Users/tmuradyan/projects/dasmeta/terraform-any-shared/modules/istio/examples/custom-chart-and-image-overrides/1-example.tf"

# Then complete implementation and docs:
Task: "Update /Users/tmuradyan/projects/dasmeta/terraform-any-shared/modules/kiali/locals.tf"
Task: "Update /Users/tmuradyan/projects/dasmeta/terraform-any-shared/modules/istio/main.tf"
```

---

## Implementation Strategy

### MVP First (US1 Only)

1. Complete Phase 1 and Phase 2.
2. Complete Phase 3 (US1).
3. Validate US1 independently.
4. Demo/deploy MVP before optional observability enhancements.

### Incremental Delivery

1. Build foundation once (Phases 1-2).
2. Deliver US1 (deploy + delegation).
3. Add US2 (Prometheus integration).
4. Add US3 (Grafana integration + FR-009 example update).
5. Finish with Phase 6 quality gates.
