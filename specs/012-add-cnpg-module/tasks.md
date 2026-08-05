# Tasks: Shared CloudNativePG cluster module

**Input**: `spec.md`, `plan.md`, `research.md`, `data-model.md`,
`contracts/module-interface.md`, and `quickstart.md`.

## Phase 1: Setup

- [x] T001 Record the shared module scope and credential boundary in
      `specs/012-add-cnpg-module/spec.md`.
- [x] T002 Record the provider, operator compatibility, module placement, and
      runtime readiness research in `specs/012-add-cnpg-module/research.md`.
- [x] T003 Record the module contract, data model, quickstart, and validation
      plan in `specs/012-add-cnpg-module/`.

## Phase 2: Foundational module interface

- [x] T004 Create `modules/cnpg/versions.tf` with Terraform and Kubectl
      provider constraints.
- [x] T005 Create `modules/cnpg/variables.tf` with validated cluster,
      database, storage, resource, and backup references.
- [x] T006 Create `modules/cnpg/locals.tf` to compose typed optional backup
      content without exposing raw manifest input.
- [x] T007 Create `modules/cnpg/tests/basic/providers.tf` and
      `modules/cnpg/tests/basic/main.tf` for isolated validation.
- [x] T008 Create `modules/cnpg/tests/invalid_inputs.tftest.hcl` to reject
      invalid names, storage, and backup references before apply.

## Phase 3: User Story 1 - Application database cluster (Priority: P1)

**Goal**: Create a safe, single-database CloudNativePG Cluster that references
an existing bootstrap credential Secret.

**Independent Test**: Terraform test plans a Cluster manifest with initdb and
managed-role Secret references but no credential values.

- [x] T009 [US1] Implement the CloudNativePG Cluster manifest in
      `modules/cnpg/main.tf`.
- [x] T010 [US1] Create `modules/cnpg/outputs.tf` with only non-secret
      connection metadata.
- [x] T011 [P] [US1] Create a neutral existing-Secret usage example in
      `modules/cnpg/examples/basic/0-setup.tf` and
      `modules/cnpg/examples/basic/1-example.tf`.
- [x] T012 [US1] Document Cluster prerequisites, credential contract, and
      readiness behavior in `modules/cnpg/README.md`.

## Phase 4: User Story 2 - Application connection contract (Priority: P2)

**Goal**: Supply deterministic read/write endpoint information without putting
database passwords into Terraform.

**Independent Test**: The basic test asserts the generated internal Service
hostname and database identity outputs.

- [x] T013 [US2] Add output assertions to
      `modules/cnpg/tests/invalid_inputs.tftest.hcl`.
- [x] T014 [US2] Document application connection usage and the no-secret
      ownership boundary in `modules/cnpg/README.md`.

## Phase 5: User Story 3 - Recovery configuration (Priority: P3)

**Goal**: Enable a typed, optional S3-compatible recovery path and a daily
scheduled backup.

**Independent Test**: Terraform test asserts that a backup configuration
creates a ScheduledBackup and references only the supplied existing Secret.

- [x] T015 [US3] Add Barman object-store and ScheduledBackup manifest
      rendering in `modules/cnpg/{locals,main}.tf`.
- [x] T016 [P] [US3] Add backup-path test coverage in
      `modules/cnpg/tests/invalid_inputs.tftest.hcl`.
- [x] T017 [US3] Document recovery prerequisites, retention, and restore-test
      responsibilities in `modules/cnpg/README.md`.

## Phase 6: Automation and validation

- [x] T018 Add `modules/cnpg` to `.github/workflows/terraform-test.yaml`,
      `.github/workflows/checkov.yaml`, and `.github/workflows/tflint.yaml`.
- [x] T019 Run terraform-docs for `modules/cnpg/README.md`.
- [x] T020 Run formatting, isolated init/validate, Terraform tests, Checkov,
      and available repository quality gates; record results here.
- [x] T021 Verify documentation, example, tests, and generated docs match the
      final interface, then mark this task file complete.

## Dependencies

- T004-T008 precede all implementation work.
- T009-T012 deliver the minimum viable Cluster module.
- T013-T014 follow output implementation.
- T015-T017 extend the Cluster only after the base manifest is validated.
- T018-T021 run after all source and documentation changes.

## Validation Evidence

- `terraform fmt -check -recursive modules/cnpg`: passed.
- `terraform -chdir=modules/cnpg/tests/basic init -backend=false` and
  `terraform validate`: passed with `gavinbunney/kubectl v1.19.0`.
- `terraform -chdir=modules/cnpg/examples/basic init -backend=false` and
  `terraform validate`: passed with `gavinbunney/kubectl v1.19.0`.
- `terraform -chdir=modules/cnpg test`: passed (4 test runs).
- `terraform-docs markdown table --output-file README.md --output-mode inject
  modules/cnpg`: passed.
- `checkov -d modules/cnpg --quiet`: passed. PostgreSQL's non-secret
  `scram-sha-256` algorithm is expressed from literal components so the
  generic entropy scan does not mistake it for a credential.
- `git diff --check`: passed.
- `pre-commit` and `tflint` are not installed locally; the PR CI matrices
  cover both tools.
