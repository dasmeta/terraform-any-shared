# Tasks: Shared ExternalSecret module

## Phase 1: Planning and contract

- [x] T001 Complete `specs/014-external-secret-module/spec.md` and its requirements checklist.
- [x] T002 Complete `specs/014-external-secret-module/{plan,research,data-model,contracts,module-interface,quickstart}.md` with direct-resource fallback and ESO v1 evidence.

## Phase 2: Foundation

- [x] T003 Add `modules/external-secret/versions.tf` with the repository Terraform and Kubectl provider constraints.
- [x] T004 Add typed and validated module variables in `modules/external-secret/variables.tf`.

## Phase 3: User Story 1 - Application Secret

**Goal**: Render one ExternalSecret from one explicit remote key and mapping list.

**Independent Test**: The fixture decodes the manifest and verifies the store, remote key, mappings, target name, type, and lifecycle policies.

- [x] T005 [US1] Implement the ExternalSecret manifest in `modules/external-secret/main.tf`.
- [x] T006 [P] [US1] Add non-sensitive resource outputs in `modules/external-secret/outputs.tf`.
- [x] T007 [US1] Add the generic application example in `modules/external-secret/examples/basic/1-example.tf`.
- [x] T008 [US1] Add manifest contract and invalid-input tests in `modules/external-secret/tests/`.

## Phase 4: User Story 2 - Basic-auth database bootstrap

**Goal**: Render a typed basic-auth target with `username` and `password` mappings.

**Independent Test**: The fixture asserts `kubernetes.io/basic-auth` and the two preserved key mappings.

- [x] T009 [US2] Extend the test fixture for a typed basic-auth target in `modules/external-secret/tests/invalid_inputs.tftest.hcl`.
- [x] T010 [US2] Document the database-bootstrap use in `modules/external-secret/README.md`.

## Phase 5: Documentation and validation

- [x] T011 Generate module, example, and test README files with terraform-docs.
- [x] T012 Register `modules/external-secret` in Terraform test, Checkov, TFLint, and pre-commit workflow matrices.
- [x] T013 Update `AGENTS.md` through the repository context script.
- [x] T014 Run formatting, validation, Terraform tests, terraform-docs, Checkov, and diff checks.
- [ ] T015 Commit, push, and open the module PR with validation evidence.
