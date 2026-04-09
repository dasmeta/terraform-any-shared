---

description: "Task list template for feature implementation"
---

# Tasks: [FEATURE NAME]

**Input**: Design documents from `/specs/[###-feature-name]/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Include test tasks whenever module behavior, inputs, outputs,
defaults, provider versions, or rendered resources change. Tests may be omitted
only for documentation-only work, and the omission MUST be justified in
`plan.md`.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Terraform module**: `modules/<module-name>/`
- **Examples**: `modules/<module-name>/examples/<scenario>/`
- **Tests**: `modules/<module-name>/tests/<scenario>/` or Terraform example
  assertions adjacent to the example when that is the established pattern
- **Automation**: `.github/workflows/`, `.pre-commit-config.yaml`
- Paths shown below assume a single target module - adjust based on `plan.md`
  structure

<!--
  ============================================================================
  IMPORTANT: The tasks below are SAMPLE TASKS for illustration purposes only.

  The /speckit.tasks command MUST replace these with actual tasks based on:
  - User stories from spec.md (with their priorities P1, P2, P3...)
  - Feature requirements from plan.md
  - Entities from data-model.md
  - Endpoints from contracts/

  Tasks MUST be organized by user story so each story can be:
  - Implemented independently
  - Tested independently
  - Delivered as an MVP increment

  DO NOT keep these sample tasks in the generated tasks.md file.
  ============================================================================
-->

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Confirm target module scope and validation baseline

- [ ] T001 Identify the target module path and in-scope examples, tests, and
      automation files from `plan.md`
- [ ] T002 Capture the current input, output, default, and provider baseline for
      the target module
- [ ] T003 [P] Record any required approvals for breaking changes, standards
      conflicts, or interface widening

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shared module changes that MUST be complete before any user story
can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

Examples of foundational tasks (adjust based on the target module):

- [ ] T004 Update `versions.tf` or `version.tf` and `providers.tf` if
      compatibility changes
- [ ] T005 [P] Update shared locals, validation, or wrapper defaults in
      `locals.tf` and `variables.tf`
- [ ] T006 [P] Prepare or extend example and test scaffolding in
      `examples/` and `tests/`
- [ ] T007 Preserve terraform-docs, pre-commit, lint, security, and release
      automation expectations for the affected paths

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - [Title] (Priority: P1) 🎯 MVP

**Goal**: [Brief description of what this story delivers]

**Independent Test**: [How to verify this story works on its own]

### Tests for User Story 1 (OPTIONAL - only if tests requested) ⚠️

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T010 [P] [US1] Add or update Terraform validation in
      `modules/<module>/tests/<scenario>/` or example assertion files
- [ ] T011 [P] [US1] Update example usage in
      `modules/<module>/examples/<scenario>/` to prove the user journey

### Implementation for User Story 1

- [ ] T012 [P] [US1] Update module inputs, defaults, or validation in
      `modules/<module>/variables.tf` and `modules/<module>/locals.tf`
- [ ] T013 [P] [US1] Update resources or upstream module wiring in
      `modules/<module>/main.tf`
- [ ] T014 [US1] Update outputs or compatibility declarations in
      `modules/<module>/outputs.tf` and version files as needed
- [ ] T015 [US1] Update `modules/<module>/README.md` to match the final
      supported interface
- [ ] T016 [US1] Run the module-specific validation commands defined in
      `plan.md`
- [ ] T017 [US1] Record any migration notes required for downstream consumers

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently

---

## Phase 4: User Story 2 - [Title] (Priority: P2)

**Goal**: [Brief description of what this story delivers]

**Independent Test**: [How to verify this story works on its own]

### Tests for User Story 2 (OPTIONAL - only if tests requested) ⚠️

- [ ] T018 [P] [US2] Add or update Terraform validation for the second user
      story path
- [ ] T019 [P] [US2] Update or add example configuration for the second user
      story path

### Implementation for User Story 2

- [ ] T020 [P] [US2] Extend module interface or defaults in exact Terraform
      files identified in `plan.md`
- [ ] T021 [US2] Implement the resource, chart, or upstream module changes for
      the second story
- [ ] T022 [US2] Update README, examples, and tests for the second story
- [ ] T023 [US2] Re-run validation for the affected module paths

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently

---

## Phase 5: User Story 3 - [Title] (Priority: P3)

**Goal**: [Brief description of what this story delivers]

**Independent Test**: [How to verify this story works on its own]

### Tests for User Story 3 (OPTIONAL - only if tests requested) ⚠️

- [ ] T024 [P] [US3] Add or update Terraform validation for the third user
      story path
- [ ] T025 [P] [US3] Update or add example configuration for the third user
      story path

### Implementation for User Story 3

- [ ] T026 [P] [US3] Extend module inputs, outputs, or resource wiring in the
      exact files identified in `plan.md`
- [ ] T027 [US3] Update documentation and examples for the third story
- [ ] T028 [US3] Re-run validation and capture any consumer-facing migration
      notes

**Checkpoint**: All user stories should now be independently functional

---

[Add more user story phases as needed, following the same pattern]

---

## Phase N: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [ ] TXXX [P] Reconcile all touched `README.md`, `examples/`, and `tests/`
- [ ] TXXX Re-run repo automation relevant to changed module paths
- [ ] TXXX Review for wrapper drift, unnecessary interface exposure, and stale
      defaults
- [ ] TXXX Confirm migration guidance or approval records are present where
      required
- [ ] TXXX Validate any quickstart or usage documentation affected by the change

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2 → P3)
- **Polish (Final Phase)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - May integrate with US1 but should be independently testable
- **User Story 3 (P3)**: Can start after Foundational (Phase 2) - May integrate with US1/US2 but should be independently testable

### Within Each User Story

- Tests MUST be written or updated before implementation when behavior or
  interface changes
- Inputs, validation, and defaults before resource wiring
- Core Terraform implementation before documentation sync
- Documentation and examples before final validation
- Story complete before moving to next priority

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- All Foundational tasks marked [P] can run in parallel (within Phase 2)
- Once Foundational phase completes, all user stories can start in parallel (if team capacity allows)
- All tests for a user story marked [P] can run in parallel
- Terraform file updates within a story marked [P] can run in parallel when
  they do not touch the same file
- Different user stories can be worked on in parallel by different team members

---

## Parallel Example: User Story 1

```bash
# Launch all validation and example tasks for User Story 1 together:
Task: "Add Terraform validation in modules/<module>/tests/<scenario>/"
Task: "Update example usage in modules/<module>/examples/<scenario>/"

# Launch disjoint Terraform file edits for User Story 1 together:
Task: "Update module inputs in modules/<module>/variables.tf"
Task: "Update resource wiring in modules/<module>/main.tf"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Test User Story 1 independently
5. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → Deploy/Demo (MVP!)
3. Add User Story 2 → Test independently → Deploy/Demo
4. Add User Story 3 → Test independently → Deploy/Demo
5. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1
   - Developer B: User Story 2
   - Developer C: User Story 3
3. Stories complete and integrate independently

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Verify tests fail before implementing when tests are required by the
  constitution
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Avoid: vague tasks, same file conflicts, undocumented interface widening, and
  missing README/example/test updates
