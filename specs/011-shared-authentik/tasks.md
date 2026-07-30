# Tasks: Shared Authentik deployment module

**Input**: `spec.md`, `plan.md`, `research.md`, `data-model.md`, and
`quickstart.md` in this directory.

## Phase 1: Feature package and repository coverage

- [x] T001 Record the Authentik scope, owner boundaries, and acceptance criteria in `specs/011-shared-authentik/spec.md`.
- [x] T002 Record official chart research, Secret contract, version decision, and Redis removal in `specs/011-shared-authentik/research.md`.
- [x] T003 Record the strict module interface and release endpoint data model in `specs/011-shared-authentik/data-model.md`.
- [x] T004 Define the implementation, validation, release risks, and no-pass-through boundary in `specs/011-shared-authentik/plan.md`.

## Phase 2: User Story 1 - External database deployment (Priority: P1)

**Goal**: Deploy the official chart into a pre-existing namespace with a
pre-existing configuration Secret and external PostgreSQL.

**Independent Test**: The basic fixture initializes and validates without a
backend; Helm template renders with bundled PostgreSQL disabled and an existing
Secret reference.

- [x] T005 [US1] Create `modules/authentik/versions.tf` with Terraform and Helm provider constraints following repository convention.
- [x] T006 [US1] Create `modules/authentik/variables.tf` with strict namespace, configuration-Secret, chart-version, and typed database inputs plus validation.
- [x] T007 [US1] Create `modules/authentik/main.tf` with official chart values, disabled bundled PostgreSQL, existing-Secret configuration, safe Helm lifecycle defaults, and no ingress.
- [x] T008 [P] [US1] Create `modules/authentik/examples/basic/main.tf` using neutral external database and Secret references.
- [x] T009 [P] [US1] Create `modules/authentik/tests/basic/providers.tf` and `modules/authentik/tests/basic/main.tf` for isolated Terraform validation.

## Phase 3: User Story 2 - Separate ingress integration (Priority: P2)

**Goal**: Make the internal Authentik server endpoint consumable by a separate
ingress configuration without this module owning ingress.

**Independent Test**: Terraform outputs derive the exact chart Service name
from the validated release name.

- [x] T010 [US2] Create `modules/authentik/outputs.tf` with release identity/status/version and server Service name/HTTP port outputs.
- [x] T011 [US2] Add release-name validation in `modules/authentik/variables.tf` so the derived Service name remains a legal Kubernetes name.

## Phase 4: User Story 3 - Deliberate operations and adoption (Priority: P3)

**Goal**: Give operators a documented, version-pinned deployment path and keep
native Authentik configuration outside Terraform.

**Independent Test**: A reader can follow the README/example/quickstart without
needing an undocumented secret or ingress action.

- [x] T012 [US3] Create `modules/authentik/README.md` with prerequisites, Secret keys, module interface, outputs, example use, upgrade note, and explicit non-goals.
- [x] T013 [US3] Add `modules/authentik` to `.github/workflows/terraform-test.yaml`.

## Phase 5: Validation and delivery evidence

- [x] T014 Run `terraform fmt -check -recursive modules/authentik`.
- [x] T015 Run `terraform -chdir=modules/authentik/tests/basic init -backend=false` and `terraform validate`.
- [x] T016 Run `helm template` against the reviewed official chart with values equivalent to the module contract; verify external PostgreSQL and existing Secret rendering.
- [x] T017 Run available repository static checks; Checkov passed, while pre-commit and tflint are not installed locally.
- [x] T018 Update this file with completed tasks and report validation evidence in the Jira ticket progress comment.

## Dependencies and execution order

- T005-T007 must precede the basic fixture and example validation.
- T010-T011 depend on the chart naming convention in T007.
- T012-T013 depend on the final interface and outputs.
- T014-T017 run after source, examples, tests, docs, and CI matrix are present.
- T018 is the evidence checkpoint before committing and pushing the feature branch.

## Validation Evidence

- `terraform fmt -check -recursive modules/authentik`: passed.
- `terraform -chdir=modules/authentik/tests/basic init -backend=false` and
  `terraform validate`: passed with `hashicorp/helm v3.2.0`.
- `terraform -chdir=modules/authentik/examples/basic init -backend=false` and
  `terraform validate`: passed with `hashicorp/helm v3.2.0`.
- `helm template` against official chart `authentik 2026.5.6`: passed;
  rendered the `authentik-server` Service, external PostgreSQL environment
  entries, and the supplied existing Secret reference with bundled PostgreSQL
  disabled.
- `checkov -d modules/authentik --quiet`: passed.
- `pre-commit` and `tflint` are not installed locally; CI remains the
  repository-hook and lint gate.
