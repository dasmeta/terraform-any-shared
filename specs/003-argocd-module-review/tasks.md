# Tasks: Argo CD module review & hardening

**Input**: Design documents from `specs/003-argocd-module-review/`  
**Prerequisites**: `plan.md` (required), `spec.md` (required), `research.md`, `data-model.md`, `quickstart.md`

**Tests**: Module behavior and interface changed, so we add example-based assertions (Terraform `2-assert.tf`) and run Terraform validation on the example.

**Workflow Guardrail**: Tasks follow the `terraform-module-developer` workflow (opinionated wrapper, aligned docs/examples, explicit versions, approval gates).

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Confirm scope and validation baseline for `modules/argocd`

- [x] T001 Capture current module interface and defaults in `modules/argocd/variables.tf`
- [x] T002 Capture current rendered values shape in `modules/argocd/main.tf` (server/configs/ingress/secret/params/autoscaling)
- [x] T003 [P] Confirm docs/examples contain no client-specific naming in `modules/argocd/README.md` and `modules/argocd/examples/basic/*`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Cross-cutting changes that block all user stories (docs/examples/tests alignment)

- [x] T004 Update provider requirements in `modules/argocd/versions.tf` (helm only; remove kubernetes provider requirement)
- [x] T005 Update module variables and defaults in `modules/argocd/variables.tf` (helm flags, ingress defaults, replicas/resources, autoscaling object, extra_configs)
- [x] T006 Update module values rendering in `modules/argocd/main.tf` (merge extra_configs layer, autoscaling mapping, replicas/resources)
- [x] T007 Add example-based assertions in `modules/argocd/examples/basic/2-assert.tf` (validate outputs and basic invariants)
- [x] T008 Update module documentation in `modules/argocd/README.md` to match the final interface (terraform-docs blocks aligned)
- [x] T009 Run formatting and static checks for the touched module files (e.g., `terraform fmt` under `modules/argocd` and example validation per `quickstart.md`)

**Checkpoint**: Foundation ready — US1/US2/US3 can be verified independently via examples + assertions

---

## Phase 3: User Story 1 - Deploy Argo CD with ALB ingress (Priority: P1) 🎯 MVP

**Goal**: Apply the module via example and reach the UI without manual post-install patches for ALB TLS termination.

**Independent Test**: `terraform apply` the example and confirm ingress is created and Argo CD server is reachable via the hostname through ALB (cluster-side verification).

### Implementation

- [x] T010 [US1] Ensure ingress controller/class are configurable with defaults in `modules/argocd/variables.tf`
- [x] T011 [US1] Ensure `hostname` is required when ingress enabled via precondition in `modules/argocd/main.tf`
- [x] T012 [US1] Ensure `server.insecure=true` is applied for ingress-enabled installs in `modules/argocd/main.tf`
- [x] T013 [US1] Update `modules/argocd/examples/basic/1-example.tf` to demonstrate ALB annotations without real ARNs/hostnames (placeholders only)
- [x] T014 [US1] Update `modules/argocd/examples/basic/README.md` to document prerequisites (ALB controller, DNS, secret mode)

---

## Phase 4: User Story 2 - Choose admin credential management mode (Priority: P2)

**Goal**: Support both admin credential modes and fail fast if misconfigured.

**Independent Test**: `terraform plan` fails if both/none are set; succeeds if exactly one is chosen.

### Implementation

- [x] T015 [US2] Keep the “exactly one mode” validation in `modules/argocd/main.tf` and ensure error message is clear
- [x] T016 [US2] Ensure `use_existing_admin_secret=true` mode does not attempt to set admin password material in `modules/argocd/main.tf`
- [x] T017 [US2] Document both modes in `modules/argocd/README.md` and ensure examples default to production-recommended mode

---

## Phase 5: User Story 3 - Override advanced chart values (Priority: P3)

**Goal**: Allow upstream chart options not in the wrapper interface via `extra_configs`.

**Independent Test**: Provide `extra_configs` in a consumer and confirm it overrides a chart value without changing module code.

### Implementation

- [x] T018 [US3] Ensure `extra_configs` is defined in `modules/argocd/variables.tf` with default `{}`
- [x] T019 [US3] Ensure Helm values include `yamlencode(var.extra_configs)` as an override layer in `modules/argocd/main.tf`
- [x] T020 [US3] Add a small documented example snippet in `modules/argocd/README.md` showing how to use `extra_configs`

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final consistency and validation

- [x] T021 Re-run `terraform fmt -recursive` for `modules/argocd/` and `modules/argocd/examples/basic/`
- [ ] T022 Re-run example validation (`terraform init`, `terraform validate`) under `modules/argocd/examples/basic` (blocked here by network restrictions to `registry.terraform.io`; run locally)
- [x] T023 Confirm README terraform-docs blocks match the final interface in `modules/argocd/README.md`
- [x] T024 Confirm placeholder-only examples (no real hostnames, account IDs, cert ARNs, or bcrypt hashes) in `modules/argocd/examples/basic/*`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)** → can start immediately
- **Foundational (Phase 2)** → blocks story verification (docs/examples/assertions)
- **User Stories (Phase 3–5)** → can proceed after Phase 2
- **Polish (Phase 6)** → after user stories are satisfied

### User Story Dependencies

- **US1 (P1)**: Depends on Phase 2
- **US2 (P2)**: Depends on Phase 2 (can be refined in parallel with US1 docs)
- **US3 (P3)**: Depends on Phase 2

### Parallel Opportunities

- [P] tasks can be done in parallel when touching different files (e.g., example README vs module README vs example asserts).

