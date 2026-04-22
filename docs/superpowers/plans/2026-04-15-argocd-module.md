# Argo CD Terraform Module (Helm) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `modules/argocd` as a maintained Terraform module that installs Argo CD via the `argo/argo-cd` Helm chart with AWS ALB ingress and a narrow, opinionated wrapper interface.

**Architecture:** Terraform module wraps a single `helm_release` and (optionally) creates the namespace. Admin password is either passed as bcrypt via chart values (stored in TF state as sensitive) or entirely delegated to an existing `argocd-secret`. Ingress config is rendered into `server.ingress.*` values for chart version `9.5.0`.

**Tech Stack:** Terraform ~> 1.3, Helm provider ~> 2.0, Kubernetes provider ~> 2.0, pre-commit `terraform_fmt` + `terraform_docs`.

---

## Files to Create / Modify

**Create:**
- `modules/argocd/README.md`
- `modules/argocd/main.tf`
- `modules/argocd/variables.tf`
- `modules/argocd/outputs.tf`
- `modules/argocd/versions.tf`
- `modules/argocd/providers.tf` (if repository conventions require explicit provider blocks for docs consistency)
- `modules/argocd/examples/basic/0-setup.tf`
- `modules/argocd/examples/basic/1-example.tf`
- `modules/argocd/examples/basic/README.md` (optional; follow local patterns)

**Modify:**
- `docs/module-housekeeping/maintained-modules.md` (add `modules/argocd/` as maintained)
- `docs/module-housekeeping/validation-coverage.md` (add to maintained list; note terraform-test status)
- `docs/module-housekeeping/exceptions.md` (only if we intentionally omit expected scaffolding)

---

### Task 1: Create `modules/argocd` scaffold (baseline files)

**Files:**
- Create: `modules/argocd/{main.tf,variables.tf,outputs.tf,versions.tf,README.md}`

- [ ] **Step 1: Create `versions.tf`**
  - Required Terraform version: `~> 1.3`
  - Required providers: `helm ~> 2.0`, `kubernetes ~> 2.0`

- [ ] **Step 2: Create `variables.tf` (narrow interface)**
  - `name` (default `"argocd"`)
  - `namespace` (default `"argocd"`)
  - `create_namespace` (default `true`)
  - `chart_version` (default `"9.5.0"`)
  - `helm_timeout` (default `900`)
  - `hostname` (default `null`; required iff `ingress.enabled = true`)
  - `ingress` object (default `{}`):
    - `enabled` optional(bool, true)
    - `annotations` optional(map(string), {})
    - `path` optional(string, "/")
    - `path_type` optional(string, "Prefix")
    - `tls_secret_name` optional(string, null)
  - Admin secret mode:
    - `admin_password_bcrypt` (default `null`, sensitive)
    - `use_existing_admin_secret` (default `false`)

- [ ] **Step 3: Create `main.tf`**
  - Locals:
    - `ingress_enabled = try(var.ingress.enabled, true)`
    - Build `server.ingress` map only when enabled:
      - `enabled = true`
      - `controller = "aws"`
      - `ingressClassName = "alb"`
      - `annotations`, `hostname`, `path`, `pathType`
      - `extraTls` only when `tls_secret_name` set:
        - `extraTls = [{ hosts = [var.hostname], secretName = tls_secret_name }]`
    - Build `values` map:
      - `server = { ingress = <computed> }` (when disabled: set only `server.ingress.enabled=false` and omit other ingress keys)
      - `configs.secret.createSecret`:
        - `true` when `admin_password_bcrypt != null`
        - `false` when `use_existing_admin_secret = true`
      - `configs.secret.argocdServerAdminPassword = var.admin_password_bcrypt` (only when set)
      - `configs.secret.argocdServerAdminPasswordMtime = ""` (let chart default handle “now” on change)
  - Resources:
    - `kubernetes_namespace_v1.this` with `count = var.create_namespace ? 1 : 0`
    - `helm_release.this`
      - repo: `https://argoproj.github.io/argo-helm`
      - chart: `argo-cd`
      - `atomic=true`, `cleanup_on_fail=true`, `wait=true`, `timeout=var.helm_timeout`, `create_namespace=false`
      - `depends_on = [kubernetes_namespace_v1.this]`
      - `values = [yamlencode(local.values)]`
      - lifecycle preconditions:
        - Exactly one admin secret mode:
          - `(var.admin_password_bcrypt != null) != (var.use_existing_admin_secret)`
        - If ingress enabled then hostname set:
          - `!local.ingress_enabled || (var.hostname != null && var.hostname != "")`

- [ ] **Step 4: Create `outputs.tf`**
  - `release_name`, `release_namespace`, `release_status`, `release_chart_version`, `helm_metadata`
  - `admin_password_secret_name` = `"argocd-secret"` (constant, but exposed for consumer wiring)
  - `ingress_hostnames` = `local.ingress_enabled ? [var.hostname] : []`

- [ ] **Step 5: Create `README.md`**
  - Short human preamble describing:
    - ALB ingress focus
    - admin password modes (bcrypt vs existing `argocd-secret`)
    - security note: bcrypt still stored in TF state
  - Include minimal usage example
  - Leave terraform-docs markers for hook

- [ ] **Step 6: Run fmt + docs**
  - Run: `pre-commit run -a terraform_fmt terraform_docs`
  - Expected: Terraform files formatted; README populated with tf-docs block

---

### Task 2: Add `examples/basic` consumer scaffold

**Files:**
- Create: `modules/argocd/examples/basic/0-setup.tf`
- Create: `modules/argocd/examples/basic/1-example.tf`
- (Optional) Create: `modules/argocd/examples/basic/README.md`

- [ ] **Step 1: Mirror existing examples patterns**
  - Inspect a comparable example (e.g. `modules/keycloak/examples/basic/0-setup.tf`) and follow naming/layout.

- [ ] **Step 2: Write `0-setup.tf`**
  - Configure providers (or rely on environment), consistent with repo patterns.

- [ ] **Step 3: Write `1-example.tf`**
  - Use an in-repo relative source that works with `terraform init -backend=false` (expected: `source = "../../"` from `modules/argocd/examples/basic`)
  - Set:
    - `hostname = "argocd.example.com"`
    - `ingress = { annotations = { ...placeholder ALB annotations... } }`
    - Prefer `use_existing_admin_secret = true`

- [ ] **Step 4: Validate example formatting**
  - Run: `terraform fmt -recursive modules/argocd/examples/basic`

---

### Task 3: Housekeeping inventory updates

**Files:**
- Modify: `docs/module-housekeeping/maintained-modules.md`
- Modify: `docs/module-housekeeping/validation-coverage.md`
- Modify: `docs/module-housekeeping/exceptions.md` (only if needed)

- [ ] **Step 1: Add `modules/argocd/` to maintained inventory**
  - Classification: `maintained`
  - README: `normalized`
  - Examples: `examples/basic`
  - Tests: `exception` (unless we add tests now)
  - Validation: `covered`
  - Status: `aligned` or `excepted` (depending on tests expectation)

- [ ] **Step 2: Add `modules/argocd` to validation coverage lists**
  - Ensure it’s included in the maintained modules lists for `checkov`, `tflint`, `pre-commit`
  - For `terraform-test`: mark as included only if the workflow already covers example-based modules; otherwise document exception.

---

### Task 4: Verification (evidence before “done”)

**Files:**
- Test: `modules/argocd/` and `modules/argocd/examples/basic/`

- [ ] **Step 1: Terraform validation (module)**
  - Run: `cd modules/argocd && terraform init -backend=false`
  - Run: `terraform validate`
  - Expected: success
  - Run: `terraform fmt -check -recursive modules/argocd`
  - Expected: no output, exit 0

- [ ] **Step 2: Terraform validation (example)**
  - Run:
    - `cd modules/argocd/examples/basic && terraform init -backend=false`
    - `terraform validate`
  - Expected: success

- [ ] **Step 3: Pre-commit full pass (repo)**
  - Run: `pre-commit run -a`
  - Expected: all hooks pass (or fix any reported issues)

---

## Execution Notes / Decisions Locked In

- Chart version pinned to `9.5.0` by default.
- Ingress is optional via `ingress.enabled`. When enabled, module forces:
  - `server.ingress.controller = "aws"`
  - `server.ingress.ingressClassName = "alb"`
- No Helm values passthrough (`helm_extra_configs`) in v1.
- Admin password is bcrypt only; plaintext passwords are out of scope.
