# Tasks: Shared Kubernetes Namespace Module

**Input**: Design documents in `specs/010-shared-namespace/`  
**Prerequisites**: `spec.md`, `plan.md`, `research.md`, `data-model.md`, and
`quickstart.md`

## Phase 1: Setup

- [X] T001 Confirm the direct-provider fallback and supported resource in `specs/010-shared-namespace/research.md`.
- [X] T002 Create the namespace module structure under `modules/k8s/namespace/`.
- [X] T003 [P] Verify repository ignore rules cover Terraform local state and provider download artifacts.

## Phase 2: Foundational Module Contract

- [X] T004 Create explicit Terraform and Kubernetes provider constraints in `modules/k8s/namespace/versions.tf`.
- [X] T005 Create typed namespace name and optional metadata inputs in `modules/k8s/namespace/variables.tf`.
- [X] T006 Define documented namespace identity outputs in `modules/k8s/namespace/outputs.tf`.

## Phase 3: User Story 1 - Create a dedicated deployment boundary (Priority: P1)

**Goal**: Create exactly one named namespace with optional caller-managed
metadata.

**Independent Test**: `modules/k8s/namespace/tests/basic` initializes and validates
against the local module without an external backend.

- [X] T007 [P] [US1] Add the baseline consumer example in `modules/k8s/namespace/examples/basic/main.tf`.
- [X] T008 [P] [US1] Add the baseline validation fixture in `modules/k8s/namespace/tests/basic/main.tf`.
- [X] T009 [US1] Implement the `kubernetes_namespace_v1` resource in `modules/k8s/namespace/main.tf`.
- [X] T010 [US1] Run format, init, and validation for `modules/k8s/namespace/tests/basic`.

## Phase 4: User Story 2 - Reuse the namespace safely (Priority: P2)

**Goal**: Document the non-secret outputs and strict ownership boundary.

**Independent Test**: The basic configuration consumes `namespace_name` and
`namespace_id` without requiring cluster-specific values.

- [X] T011 [US2] Update `modules/k8s/namespace/tests/basic/main.tf` to consume identity outputs.
- [X] T012 [US2] Document inputs, outputs, exclusions, and basic usage in `modules/k8s/namespace/README.md`.
- [X] T013 [US2] Re-run format, init, and validation for `modules/k8s/namespace/tests/basic`.

## Phase 5: Polish and Validation

- [X] T014 Run repository-relevant formatting, documentation, and static checks for `modules/k8s/namespace/`.
- [X] T015 Review new Terraform and examples for customer-specific names, hostnames, secret values, and unsupported pass-through inputs.
- [X] T016 Mark completed tasks and record validation evidence in `specs/010-shared-namespace/tasks.md`.
- [X] T017 Move the module beneath `modules/k8s/`, document the retained dashboard asset, and update the Terraform validation matrix to the new path.
- [X] T018 Register `modules/k8s/namespace` in the Checkov, TFLint, and pre-commit matrices alongside the Terraform validation matrix.
- [X] T019 Validate `name` as a Kubernetes DNS-1123 label and add an executable invalid-input test.

## Dependencies and Execution Order

`T001`–`T006` establish the module contract. `T007` and `T008` can proceed in
parallel after the contract files exist. `T009` follows the test/example
scaffolding; `T010` validates the P1 increment. `T011`–`T013` complete the
consumer-output story. `T014`–`T016` close the module package.

## Implementation Strategy

Deliver P1 first: one namespace resource, minimal metadata, and an executable
fixture. Then document outputs and exclusions. Do not add quotas, policies,
service accounts, or other shared capabilities in this feature.

## Validation Evidence

- `terraform fmt -check -recursive modules/k8s/namespace`: passed.
- `terraform -chdir=modules/k8s/namespace/tests/basic init -backend=false`:
  passed with `hashicorp/kubernetes v2.38.0`.
- `terraform -chdir=modules/k8s/namespace/tests/basic validate`: passed.
- `terraform -chdir=modules/k8s/namespace/examples/basic init -backend=false`:
  passed with `hashicorp/kubernetes v2.38.0`.
- `terraform -chdir=modules/k8s/namespace/examples/basic validate`: passed.
- `checkov -d modules/k8s/namespace --quiet`: passed.
- `terraform -chdir=modules/k8s/namespace test`: passed; rejects a non-DNS-1123
  namespace name with a mocked Kubernetes provider.
- `pre-commit` is not installed locally; CI remains the repository-hook gate.
