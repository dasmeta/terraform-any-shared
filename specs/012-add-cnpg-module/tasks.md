# Tasks: Shared CloudNativePG cluster module

**Input**: the active `spec.md`, `plan.md`, `research.md`, `data-model.md`,
`contracts/module-interface.md`, and `quickstart.md`.

## Phase 1: Review-driven scope correction

- [x] T001 Update `specs/012-add-cnpg-module/{spec,plan,research}.md` with the
      shared module standards, sourcing analysis, capability classifications,
      and cluster-only scope.
- [x] T002 Remove delivered template placeholders from the Speckit package.
- [x] T003 Record that the user approved removal of unreleased deprecated
      backup, ScheduledBackup, and PodMonitor interfaces.

## Phase 2: Cluster contract

- [x] T004 Add inline comments to every grouped `storage`, `database`, and
      `resources` field in `modules/cnpg/variables.tf`.
- [x] T005 Strengthen identity and storage validation in
      `modules/cnpg/variables.tf`.
- [x] T006 Remove cluster-only exclusions from
      `modules/cnpg/{variables,locals,main,outputs}.tf` and delete unused
      `locals.tf`.
- [x] T007 Enforce SCRAM, use a published multi-architecture image reference,
      propagate inherited metadata, and explain manifest wait semantics in
      `modules/cnpg/main.tf`.
- [x] T008 Add deterministic `-ro` and `-r` connection outputs in
      `modules/cnpg/outputs.tf`.

## Phase 3: Documentation and repository automation

- [x] T009 Align `modules/cnpg/README.md`, the basic example, and test fixture
      with cluster-only scope and the managed-role limitation.
- [x] T010 Add generated `README.md` files under `modules/cnpg/examples/basic`
      and `modules/cnpg/tests/basic`.
- [x] T011 Register `modules/cnpg` in `.github/workflows/pre-commit.yaml`.
- [x] T012 Update `AGENTS.md` with the CNPG/Kubectl module technology and
      recent change record.

## Phase 4: Verification

- [x] T013 Extend `modules/cnpg/tests/invalid_inputs.tftest.hcl` for the
      corrected validation, metadata, encryption, and service output contract.
- [x] T014 Run formatting, isolated init/validate, Terraform tests,
      terraform-docs, Checkov, pre-commit, TFLint, and diff checks.
- [ ] T015 Commit, push, and update PR #70 with validation evidence.

## Validation Evidence

- `terraform fmt -check -recursive modules/cnpg` passed.
- Isolated `terraform validate` passed for the basic example and test fixture.
- `terraform -chdir=modules/cnpg test` passed: 4 passed, 0 failed.
- `terraform-docs` regenerated the module, example, and test fixture README files.
- `checkov -d modules/cnpg --quiet` and `git diff --check` passed.
- `pre-commit` and `tflint` are not installed in the local environment; the
  repository workflow runs both for `modules/cnpg` after this push.
