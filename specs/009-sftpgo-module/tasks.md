# Tasks: SFTPGo Terraform Module

**Input**: Design documents from `specs/009-sftpgo-module/`  
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/module-interface.md, quickstart.md

**Tests**: Required because this change adds a new module interface and behavior.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Confirm target module scope and create the module skeleton.

- [X] T001 Create `modules/sftpgo/` with `main.tf`, `locals.tf`, `variables.tf`, `outputs.tf`, `versions.tf`, and `README.md`.
- [X] T002 [P] Create `modules/sftpgo/examples/basic/` with `0-setup.tf`, `1-example.tf`, and `README.md`.
- [X] T003 [P] Create `modules/sftpgo/tests/basic/` with `providers.tf`, `main.tf`, and `README.md`.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Define compatibility and shared input contract before user story implementation.

**CRITICAL**: No user story work can begin until this phase is complete.

- [X] T004 Add Terraform and Helm provider constraints in `modules/sftpgo/versions.tf`.
- [X] T005 Define grouped variables and sensitive inputs in `modules/sftpgo/variables.tf`.
- [X] T006 Define deterministic value-building locals in `modules/sftpgo/locals.tf`.

**Checkpoint**: Foundation ready - user story implementation can now begin.

---

## Phase 3: User Story 1 - Deploy SFTPGo With S3 Storage (Priority: P1) MVP

**Goal**: Deploy SFTPGo through Helm with required S3-backed storage and common deployment settings.

**Independent Test**: Terraform validates the module and basic example with S3 storage inputs.

### Tests for User Story 1

- [X] T007 [P] [US1] Add basic example S3 deployment usage in `modules/sftpgo/examples/basic/1-example.tf`.
- [X] T008 [P] [US1] Add test fixture S3 deployment usage in `modules/sftpgo/tests/basic/main.tf`.

### Implementation for User Story 1

- [X] T009 [US1] Implement `helm_release.this` with SFTPGo chart wiring in `modules/sftpgo/main.tf`.
- [X] T010 [US1] Add release and namespace outputs in `modules/sftpgo/outputs.tf`.
- [X] T011 [US1] Document baseline deployment usage in `modules/sftpgo/README.md`.

**Checkpoint**: User Story 1 should be functional and independently validatable.

---

## Phase 4: User Story 2 - Bootstrap Admin And Users (Priority: P2)

**Goal**: Generate SFTPGo admin and user bootstrap values from sensitive Terraform variables.

**Independent Test**: Terraform validates bootstrap admin and user configuration and generated values remain deterministic.

### Tests for User Story 2

- [X] T012 [P] [US2] Extend `modules/sftpgo/examples/basic/1-example.tf` with admin and bootstrap user inputs.
- [X] T013 [P] [US2] Extend `modules/sftpgo/tests/basic/main.tf` with admin and bootstrap user inputs.

### Implementation for User Story 2

- [X] T014 [US2] Add bootstrap user sidecar value generation in `modules/sftpgo/locals.tf`.
- [X] T015 [US2] Wire bootstrap values into `helm_release.this` in `modules/sftpgo/main.tf`.
- [X] T016 [US2] Document sensitive variable behavior and state implications in `modules/sftpgo/README.md`.

**Checkpoint**: User Stories 1 and 2 should both work independently.

---

## Phase 5: User Story 3 - Consume Documented Module Contract (Priority: P3)

**Goal**: Make the module adoptable from README, example, and test artifacts without customer-specific references.

**Independent Test**: Documentation, examples, and tests match the final interface and contain only neutral placeholders.

### Tests for User Story 3

- [X] T017 [P] [US3] Add example README usage notes in `modules/sftpgo/examples/basic/README.md`.
- [X] T018 [P] [US3] Add test fixture README notes in `modules/sftpgo/tests/basic/README.md`.

### Implementation for User Story 3

- [X] T019 [US3] Complete `modules/sftpgo/README.md` with prerequisites, supported boundaries, usage, and terraform-docs-compatible sections.
- [X] T020 [US3] Review all `modules/sftpgo` files for neutral naming and no real secrets.

**Checkpoint**: All user stories should now be independently functional.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final validation and Speckit evidence alignment.

- [X] T021 Run `terraform fmt -recursive modules/sftpgo`.
- [X] T022 Run `terraform -chdir=modules/sftpgo init -backend=false` and `terraform -chdir=modules/sftpgo validate`.
- [X] T023 Run `terraform -chdir=modules/sftpgo/examples/basic init -backend=false` and `terraform -chdir=modules/sftpgo/examples/basic validate`.
- [X] T024 Run `terraform -chdir=modules/sftpgo/tests/basic init -backend=false` and `terraform -chdir=modules/sftpgo/tests/basic validate`.
- [X] T025 Update `AGENTS.md` with the new active technology and recent change entry for `009-sftpgo-module`.
- [X] T026 Mark completed tasks in `specs/009-sftpgo-module/tasks.md`.
- [X] T027 Add `modules/sftpgo` to repository module-housekeeping inventory and validation workflow matrices so the module follows maintained-module coverage conventions.
- [X] T028 Expand the basic example to show the full environment-style provider setup and SFTPGo inputs using neutral placeholders.
- [X] T029 Fix bootstrap user password-change flag mapping to SFTPGo `filters.require_password_change` and document WebClient/REST API scope.
- [X] T030 Add a failing test fixture for optional SFTP-only LoadBalancer exposure.
- [X] T031 Add the Kubernetes provider constraint required by the optional SFTP Service resource.
- [X] T032 Add grouped `sftp_service` input for optional SFTP-only TCP exposure.
- [X] T033 Implement separate `kubernetes_service_v1` for SFTP-only exposure.
- [X] T034 Add SFTP Service outputs.
- [X] T035 Update README, example, and test notes for SFTP-only exposure.
- [X] T036 Run `terraform fmt -recursive modules/sftpgo`.
- [X] T037 Run module, example, and test fixture Terraform validation.
- [X] T038 Add a failing test fixture for the grouped `web_session` input. The expected schema failure was masked by the local provider architecture mismatch during validation.
- [X] T039 Add validated sensitive `web_session` input and `config.httpd` Helm value mapping.
- [X] T040 Update the example, README, and test notes for stable signing and cookie settings.
- [X] T041 Configure the dev consumer with stable WebUI session settings.
- [ ] T042 Run formatting, module/example/test validation, and diff checks for the session extension.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies.
- **Foundational (Phase 2)**: Depends on Setup completion and blocks all user stories.
- **User Story 1 (Phase 3)**: Depends on Foundational.
- **User Story 2 (Phase 4)**: Depends on Foundational and integrates with User Story 1 values.
- **User Story 3 (Phase 5)**: Depends on User Stories 1 and 2.
- **Polish (Phase 6)**: Depends on selected user stories being complete.

### Parallel Opportunities

- T002 and T003 can run in parallel.
- T007 and T008 can run in parallel.
- T012 and T013 can run in parallel.
- T017 and T018 can run in parallel.

## Implementation Strategy

1. Complete setup and foundational interface files.
2. Deliver User Story 1 as the minimum deployable Helm wrapper.
3. Add User Story 2 bootstrap behavior.
4. Complete documentation and validation artifacts.
5. Run validation and record any limitations.
