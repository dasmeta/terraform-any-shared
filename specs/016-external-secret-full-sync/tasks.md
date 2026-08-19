# Tasks: ExternalSecret full sync mode

## Phase 1: Planning and contract

- [x] T001 Complete `specs/016-external-secret-full-sync/spec.md` and its requirements checklist.
- [x] T002 Complete `specs/016-external-secret-full-sync/{plan,research,data-model,quickstart}.md` and `contracts/module-interface.md`, recording the narrowing of the 014 `dataFrom` exclusion.

## Phase 2: Foundation

- [x] T003 Add the `sync_all` boolean variable, default `false`, in `modules/external-secret/variables.tf`.
- [x] T004 Give `mappings` a `[]` default and keep only content rules (non-blank values, unique `secret_key`) in its validation block.

## Phase 3: User Story 1 - Full sync

**Goal**: Extract every property of one remote key into the target Secret.

**Independent Test**: `renders_full_sync_extract_all` decodes the manifest and asserts `spec.dataFrom[0].extract.key` equals the remote key and that `spec` has no `data` attribute.

- [x] T005 [US1] Build `spec` with `merge()` in `modules/external-secret/main.tf` so `sync_all = true` emits `dataFrom[].extract` and omits `data`.
- [x] T006 [US1] Add the `renders_full_sync_extract_all` run to `modules/external-secret/tests/invalid_inputs.tftest.hcl`.

## Phase 4: User Story 2 - Preserved list-sync default

**Goal**: Existing consumers see an unchanged interface and an unchanged manifest.

**Independent Test**: The pre-existing runs (`renders_typed_basic_auth_secret`, `rejects_duplicate_target_keys`, `rejects_invalid_target_policy`) pass without edits.

- [x] T007 [US2] Keep the `data[]` branch byte-identical under the `merge()` restructure; leave `outputs.tf` and `versions.tf` untouched.
- [x] T008 [US2] Keep `examples/basic` and `tests/basic` on the least-privilege list-sync path.

## Phase 5: User Story 3 - Mode exclusivity

**Goal**: Reject both invalid mode combinations at plan time.

**Independent Test**: `rejects_sync_all_with_mappings` and `rejects_list_sync_without_mappings` both expect a failure on `kubectl_manifest.external_secret`.

- [x] T009 [US3] Add the `lifecycle.precondition` in `modules/external-secret/main.tf` with a message naming both valid modes.
- [x] T010 [US3] Add both rejection runs to `modules/external-secret/tests/invalid_inputs.tftest.hcl`.

## Phase 6: Documentation and validation

- [x] T011 Document the full-sync mode, its example, and the least-privilege recommendation in `modules/external-secret/README.md`.
- [x] T012 Refresh the terraform-docs inputs table for `sync_all` and the relaxed `mappings`.
- [x] T013 Run `terraform fmt -check -recursive`, `terraform validate`, and `terraform test` in `modules/external-secret`. Result on 2026-08-07: fmt clean, validate `Success!`, tests `6 passed, 0 failed`.
- [ ] T014 Confirm terraform-docs, TFLint, Checkov, and pre-commit pass in CI. Those tools are not installed locally, so the pull request checks are the verification of record.
- [ ] T015 Commit, push, and open the pull request with the validation evidence and the `dataFrom` scope-narrowing note for reviewer approval.

## Notes

- No CI workflow matrix change is required: no module path is added or removed.
- `AGENTS.md` needs no new technology entry; the ESO v1 Kubectl stack from 014 is unchanged.
