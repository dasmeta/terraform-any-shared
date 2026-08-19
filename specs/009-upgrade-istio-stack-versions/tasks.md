# Tasks: Upgrade Istio Stack Tooling Versions

**Input**: Design documents from `/specs/009-upgrade-istio-stack-versions/`
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/module-interface.md`, `quickstart.md`

**Tests**: Verification is performed by applying the `chart-direct-tgz-sources` example on a local docker-desktop cluster (no unit test framework changes needed for a defaults-only version bump).

**Organization**: Tasks are grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Confirm scope and lock the version baseline.

- [x] T001 Capture current defaults (Istio `1.29.2`, Gateway API CRDs `v1.5.1`, Kiali `2.25.0`) as the implementation baseline in `specs/009-upgrade-istio-stack-versions/quickstart.md`
- [x] T002 Identify the local verification example path `modules/istio/examples/chart-direct-tgz-sources`
- [x] T003 [P] Confirm latest stable versions from upstream origins (istio-release charts, kubernetes-sigs/gateway-api releases, kiali.org/helm-charts) and record in `specs/009-upgrade-istio-stack-versions/research.md`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Prepare the CRD manifest and version-contract groundwork.

**⚠️ CRITICAL**: CRD manifest must exist before the crdsList/version defaults are updated.

- [x] T004 Download the official Gateway API v1.6.1 standard-install manifest to `modules/gateway-api-crds/files/v1.6.1-standard-install.yaml`
- [x] T005 Confirm the v1.6.1 document set (10 CRDs + ValidatingAdmissionPolicy + ValidatingAdmissionPolicyBinding) and that CRD/VAP apiVersions are unchanged from v1.5.1

**Milestone**: Foundation complete; version-default work can proceed.

---

## Phase 3: User Story 1 - Consume up-to-date Istio stack defaults (Priority: P1) 🎯 MVP

**Goal**: Move default Istio and Kiali versions to latest stable without breaking default consumer flow.

**Independent Test**: Apply the example and confirm istiod image `1.30.3` and Kiali operator `2.29.0`.

### Implementation for User Story 1

- [x] T006 [US1] Update Istio fallback `chart.version` default `1.29.2` -> `1.30.3` in `modules/istio/variables.tf`
- [x] T007 [US1] Update Kiali operator fallback `chart_version` default `2.25.0` -> `2.29.0` in `modules/istio/variables.tf`
- [x] T008 [US1] Update Kiali module `chart_version` default `2.25.0` -> `2.29.0` in `modules/kiali/variables.tf`
- [x] T009 [US1] Keep the gateway-api resources chart fallback at `0.1.7` (no content change) in `modules/istio/variables.tf`

**Milestone**: US1 defaults updated and independently verifiable.

---

## Phase 4: User Story 2 - Gateway API v1.6 standard-channel routes (Priority: P2)

**Goal**: Install the v1.6.1 CRD bundle including the newly-GA `tcproutes`/`udproutes`.

**Independent Test**: Apply CRDs and confirm `tcproutes`/`udproutes` CRDs exist and the chart renders them at `v1`.

### Implementation for User Story 2

- [x] T010 [US2] Update CRD default `version` `v1.5.1` -> `v1.6.1` in `modules/gateway-api-crds/variables.tf`
- [x] T011 [US2] Add `tcproutes` and `udproutes` entries to the `crdsList` default in `modules/gateway-api-crds/variables.tf`
- [x] T012 [US2] Retain `files/v1.5.1-standard-install.yaml` for rollback

**Milestone**: US2 CRD contract updated and independently verifiable.

---

## Phase 5: User Story 3 - Safe in-place upgrade of a running cluster (Priority: P3)

**Goal**: Prove an existing deployment upgrades in place with no destroys and a working endpoint.

**Independent Test**: On a cluster running the old versions, apply the upgraded example; expect additions + in-place updates, 0 destroys.

### Implementation for User Story 3

- [x] T013 [US3] Bump example versions (`istio_version = 1.30.3`, `kiali_chart_version = 2.29.0`; gateway-api stays `0.1.7`) in `modules/istio/examples/chart-direct-tgz-sources/1-example.tf`
- [x] T014 [US3] Server-side dry-run the v1.6.1 CRD manifest against a live cluster to confirm the `safe-upgrades` policy accepts the change
- [x] T015 [US3] Apply the example on docker-desktop and confirm plan shows additions + updates, 0 destroys

**Milestone**: US3 in-place upgrade verified.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final consistency and verification.

- [x] T016 [P] Run `terraform fmt -recursive` on `modules/istio`, `modules/gateway-api-crds`, `modules/kiali`
- [x] T017 Run `terraform validate` on affected module/example paths
- [x] T018 Verify deployed versions on docker-desktop: istiod `1.30.3`, Gateway API CRD bundle-version `v1.6.1`, `tcproutes`/`udproutes` present
- [x] T019 Verify the test endpoint `http://http-echo-chart-direct-tgz-sources.localhost/ping` responds successfully

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: Starts immediately.
- **Phase 2 (Foundational)**: Depends on Phase 1; blocks the CRD user story.
- **Phase 3 (US1)**: Depends on Phase 1 (version confirmation).
- **Phase 4 (US2)**: Depends on Phase 2 (manifest present).
- **Phase 5 (US3)**: Depends on US1 + US2 (defaults + CRDs in place).
- **Phase 6 (Polish)**: Depends on completion of the user stories.

### Parallel Opportunities

- T003 can run alongside T001/T002.
- US1 (version defaults) and US2 (CRD contract) implementation can proceed in parallel after Phase 2.

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1 and Phase 2.
2. Deliver Phase 3 (US1) version defaults end-to-end.
3. Validate US1 independently as MVP.

### Incremental Delivery

1. Foundation (Phases 1-2).
2. US1 (version defaults, MVP).
3. US2 (CRD v1.6.1 contract).
4. US3 (in-place upgrade verification).
5. Polish and full-path validation on docker-desktop.
