# Tasks: Reusable random secret values module

## Phase 1: Setup

- [X] T001 Create the `modules/random-secret-values` Terraform module structure and explicit Random provider version in `modules/random-secret-values/versions.tf`
- [X] T002 Add the module path to `.github/workflows/terraform-test.yaml`, `.github/workflows/pre-commit.yaml`, `.github/workflows/tflint.yaml`, and `.github/workflows/checkov.yaml`

## Phase 2: Foundational validation

- [X] T003 Define the narrow generated-values, static-values, and aliases input contract with validation in `modules/random-secret-values/variables.tf`
- [X] T004 Implement collision and alias-source validation locals in `modules/random-secret-values/locals.tf`

## Phase 3: User Story 1 - Generate reusable secret values (P1)

**Goal**: Produce independently stable named random values in one sensitive result map.

**Independent Test**: The basic test applies two policies and verifies their key set and lengths without exposing results.

- [X] T005 [US1] Create one `random_password` resource per generated policy in `modules/random-secret-values/main.tf`
- [X] T006 [US1] Expose the sensitive values map and safe result key list in `modules/random-secret-values/outputs.tf`
- [X] T007 [P] [US1] Add the basic generated-value fixture in `modules/random-secret-values/tests/basic/main.tf`
- [X] T008 [US1] Add safe basic assertions in `modules/random-secret-values/tests/basic/2-assert.tf`

## Phase 4: User Story 2 - Compose application credential payloads (P2)

**Goal**: Merge static values and aliases without duplicate credentials.

**Independent Test**: The basic fixture verifies a static username and a password alias equal the generated source.

- [X] T009 [US2] Merge static values and aliases into the sensitive result map in `modules/random-secret-values/locals.tf`
- [X] T010 [US2] Add invalid-policy, collision, and alias-source tests in `modules/random-secret-values/tests/invalid_inputs.tftest.hcl`
- [X] T011 [P] [US2] Add a documented application credential example in `modules/random-secret-values/examples/basic/0-setup.tf` and `modules/random-secret-values/examples/basic/1-example.tf`

## Phase 5: Documentation and verification

- [X] T012 Document responsibility boundaries and AWS Secret consumer composition in `modules/random-secret-values/README.md`
- [X] T013 Run terraform fmt, terraform init/test, terraform-docs, tflint, Checkov, and pre-commit for the new module; record results in `specs/015-random-secret-values/tasks.md`

## Dependencies

- T001-T004 block all implementation.
- T005-T008 deliver the P1 minimum viable module.
- T009-T011 extend the P1 result for payload composition.
- T012-T013 complete delivery.

## Verification record

- `terraform fmt -check -recursive modules/random-secret-values`: passed.
- `terraform -chdir=modules/random-secret-values test`: passed (5 tests).
- Basic example and basic fixture `terraform init -backend=false` and `terraform validate`: passed.
- `terraform-docs` regenerated module, example, and fixture README files.
- `git diff --check`: passed.
- `tflint`, `checkov`, and `pre-commit` are not installed in this local environment; the updated CI matrices will run them in the pull request.
