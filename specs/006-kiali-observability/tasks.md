# Tasks: Kiali Observability For Istio

**Input**: Design documents from `specs/006-kiali-observability/`
**Prerequisites**: `plan.md`, `spec.md`

**Tests**: This changes module behavior and interface. Validation tasks are required.

## Phase 1: Setup

- [x] T001 Identify target module path as `modules/kiali` with `modules/istio` delegation
- [x] T002 Capture current Istio module baseline in `modules/istio/main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`, and `README.md`
- [x] T003 Check official Kiali docs for Helm install, Kiali CR, Prometheus, and Grafana fields

## Phase 2: Foundational

- [x] T004 Add standalone `configs` grouped input shape in `modules/kiali/variables.tf`
- [x] T005 Add render locals for Kiali CR spec in `modules/kiali/locals.tf`
- [x] T006 Add Kiali operator Helm release in `modules/kiali/main.tf`
- [x] T007 Add Kiali CR manifest in `modules/kiali/main.tf`
- [x] T007A Add optional `modules/kiali` delegation in `modules/istio/main.tf`

## Phase 3: User Story 1 - Deploy Kiali With Istio

- [x] T008 [US1] Add Kiali operator and Kiali CR outputs in `modules/kiali/outputs.tf` and delegated outputs in `modules/istio/outputs.tf`
- [x] T009 [US1] Add `modules/kiali/examples/basic/0-setup.tf`
- [x] T010 [US1] Add `modules/kiali/examples/basic/1-example.tf`
- [x] T010A [US1] Add `modules/istio/examples/kiali-observability/`

## Phase 4: User Story 2 - Connect Kiali To Prometheus

- [x] T011 [US2] Ensure Prometheus URL and common settings render under `spec.external_services.prometheus`
- [ ] T012 [US2] Document Prometheus integration in `modules/istio/README.md`

## Phase 5: User Story 3 - Connect Kiali To Grafana

- [x] T013 [US3] Ensure Grafana enablement, URLs, datasource UID, dashboards, and auth render under `spec.external_services.grafana`
- [ ] T014 [US3] Document Grafana integration in `modules/istio/README.md`

## Phase 6: Validation

- [ ] T015 Run `terraform fmt -recursive modules/istio`
- [ ] T016 Run `terraform -chdir=modules/istio init -backend=false` when provider access is available
- [ ] T017 Run `terraform -chdir=modules/istio validate` when initialization succeeds
- [ ] T018 Review `git diff` for unrelated changes and wrapper drift
