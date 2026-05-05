# Tasks: Keycloak module production readiness

**Input**: Design documents from `specs/005-keycloak-module-review/`  
**Prerequisites**: `plan.md` (required), `spec.md` (required), plus `research.md`, `data-model.md`, `contracts/`, `quickstart.md`

**Tests**: Include test tasks whenever module behavior, inputs, outputs, defaults, provider versions, or rendered resources change.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Confirm target module scope and validation baseline

- [x] T001 Confirm in-scope paths for this change (modules/keycloak/* and specs/005-keycloak-module-review/*)
- [x] T002 Capture validation commands for this module (terraform fmt/validate; pre-commit hooks) in `specs/005-keycloak-module-review/quickstart.md`
- [x] T003 [P] Verify no sensitive values remain in committed examples (`modules/keycloak/examples/basic/*`) and docs
- [x] T004 Document RBAC limitation: if namespace creation is unauthorized, set `create_namespace=false` and pre-create namespace (modules/keycloak/README.md and modules/keycloak/examples/basic/1-example.tf)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shared module changes that MUST be complete before user story verification

- [x] T005 Review module boundary and interface constraints (opinionated wrapper, `extra_configs` escape hatch) in `modules/keycloak/README.md`
- [x] T006 [P] Ensure provider/version requirements are explicit and unchanged unless justified (`modules/keycloak/versions.tf`)
- [x] T007 [P] Ensure terraform-docs blocks are consistent and preserved in `modules/keycloak/README.md`
- [x] T008 Prepare example scaffolding for safe-to-run local validation in `modules/keycloak/examples/basic/0-setup.tf` and `modules/keycloak/examples/basic/1-example.tf`

**Checkpoint**: Foundation ready — proceed to user story tasks

---

## Phase 3: User Story 1 - Deploy production-aligned Keycloak (Priority: P1) 🎯 MVP

**Goal**: Keycloak works behind TLS-terminating ingress/LB without redirect loops and supports multi-replica operation with supported cache discovery defaults.

**Independent Test**: Apply the example to a test namespace with a separate DB and verify UI and OIDC discovery URLs use HTTPS and cluster continues through a pod restart.

### Tests / Verification for User Story 1

- [x] T010 [P] [US1] Add/refresh terraform validate coverage in `modules/keycloak/tests/basic/*` for new variables (hostname/proxy/cache/flags)
- [ ] T011 [US1] Manual smoke test (optional): apply `modules/keycloak/examples/basic` to a test namespace + test DB, verify no redirect loop at public URL

### Implementation for User Story 1

- [x] T013 [P] [US1] Ensure Keycloak public URL is HTTPS-aware by default when ingress is enabled (`assume_https_public_endpoint`) in `modules/keycloak/main.tf` and `modules/keycloak/variables.tf`
- [x] T014 [P] [US1] Ensure reverse-proxy headers mode is configurable and documented (`proxy_mode`) in `modules/keycloak/main.tf`, `modules/keycloak/variables.tf`, and `modules/keycloak/README.md`
- [x] T015 [P] [US1] Ensure clustering/cache stack is explicit and configurable (`cache_stack`) in `modules/keycloak/main.tf` and `modules/keycloak/variables.tf`
- [x] T016 [US1] Ensure example/test docs include guidance on separate DB and hostname for test installs (`modules/keycloak/examples/basic/1-example.tf`, `modules/keycloak/README.md`)

**Checkpoint**: US1 can be validated independently.

---

## Phase 4: User Story 2 - Observe health, failures, and latency (Priority: P2)

**Goal**: Operators can scrape metrics, observe event counters for auth/token flows, and use logs/health endpoints for troubleshooting.

**Independent Test**: With metrics enabled and scraping configured (ServiceMonitor or annotations), metrics exist and support basic alerts; logs include relevant categories.

### Tests / Verification for User Story 2

- [x] T020 [P] [US2] Verify module enables metrics/health by default and preserves chart behavior (readiness probe requires both) via `terraform validate` and example plan (`modules/keycloak/main.tf`)
- [x] T021 [P] [US2] Verify ServiceMonitor is optional/off by default to avoid CRD dependency (example + README) (`modules/keycloak/variables.tf`, `modules/keycloak/README.md`)
- [ ] T022 [US2] Manual verification (optional): in a cluster with Prometheus Operator, enable `service_monitor.enabled=true` and confirm a target appears in Prometheus

### Implementation for User Story 2

- [x] T023 [P] [US2] Add/validate ServiceMonitor configuration passthrough (`service_monitor.*`) in `modules/keycloak/main.tf` and `modules/keycloak/variables.tf`
- [x] T024 [P] [US2] Add/validate user event metrics controls (`event_metrics.*`) in `modules/keycloak/main.tf` and `modules/keycloak/variables.tf`
- [x] T025 [P] [US2] Add/validate HTTP latency histogram controls (`http_metrics_histograms`, `http_metrics_slos`) in `modules/keycloak/main.tf` and `modules/keycloak/variables.tf`
- [x] T026 [P] [US2] Add/validate log controls (`log_level`, `log_categories`) and document recommended categories in `modules/keycloak/README.md`

**Checkpoint**: US2 can be validated independently.

---

## Phase 5: User Story 3 - Safe module consumption and upgrades (Priority: P3)

**Goal**: Interface remains opinionated and upgrades remain safe; docs/examples/tests reflect supported usage.

**Independent Test**: Consumers can follow README + example, and repo automation hooks (fmt/docs) run cleanly.

### Tasks for User Story 3

- [x] T030 [P] [US3] Ensure `extra_configs` remains the primary escape hatch for unmodeled chart options (`modules/keycloak/main.tf`, `modules/keycloak/variables.tf`, `modules/keycloak/README.md`)
- [x] T031 [P] [US3] Ensure secrets guidance is correct (raw password vs existing secret) and doesn’t encourage committing secrets; reference T003 for “no secrets in examples” checks (`modules/keycloak/README.md`)
- [x] T032 [US3] Run module-level gates locally (terraform fmt, terraform validate, terraform-docs via pre-commit) for `modules/keycloak/*`

**Checkpoint**: US3 can be validated independently.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final consistency and completeness pass

- [ ] T040 Reconcile terminology across docs/spec (hostname/proxy/cache/ServiceMonitor) in `modules/keycloak/README.md` and `specs/005-keycloak-module-review/*` (do not duplicate T003)
- [x] T041 Re-run pre-commit on changed paths and confirm no files are modified by hooks afterwards
- [x] T042 Confirm no approval-gated interface widening occurred; if it did, record it explicitly in spec/plan before merge

---

## Dependencies & Execution Order

- Phase 1 → Phase 2 → User Stories (US1 then US2 then US3) → Polish
- Within each user story, tasks marked **[P]** can run in parallel.

## Parallel Execution Examples

- **[US1]**: `T013`, `T014`, `T015` can be done in parallel; `T016` depends on them.
- **[US2]**: `T023`, `T024`, `T025`, `T026` can be done in parallel; docs checks follow.

