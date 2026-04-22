# Argo CD Terraform Module (Helm) — Design Spec

Date: 2026-04-15
Status: draft (approved approach: **Approach 1 — strict opinionated wrapper**)

## Goal

Add a new maintained Terraform module at `modules/argocd/` that installs Argo CD
into an **existing** Kubernetes cluster using the Helm chart `argo/argo-cd`,
following the repository’s wrapper-module conventions:

- narrow, opinionated interface for the common path
- no generic “values passthrough”
- consumer-managed ingress controller (AWS ALB ingress)
- explicit, mutually-exclusive admin secret modes (Helm-managed `argocd-secret` vs existing `argocd-secret`)

Non-goals:

- managing AWS ALB infrastructure (target groups, listeners, ACM, DNS)
- managing cluster lifecycle
- implementing SSO/OIDC/Dex (out of scope for this first version)
- exposing the upstream Helm chart’s entire configuration surface

## Intended Consumers / Preconditions

- A Kubernetes cluster reachable via the `helm` and `kubernetes` providers
- AWS Load Balancer Controller already installed and configured in the cluster
- If exposing UI publicly: DNS already points at the ALB, and TLS/cert strategy is consumer-managed

## Proposed Module Surface (Inputs)

### Release / Namespace

- `name` (string, default `"argocd"`): Helm release name
- `namespace` (string, default `"argocd"`): target namespace
- `create_namespace` (bool, default `true`): create namespace prior to secrets + Helm

### Chart pinning

- `chart_version` (string, default `"9.5.0"`): pinned Argo CD chart version (spec validated against `argo/argo-cd` chart `9.5.0`)
- Helm repository fixed to `https://argoproj.github.io/argo-helm`
- Chart fixed to `argo-cd`

### Helm install behavior

- `helm_timeout` (number, default `900`): seconds Helm waits when `wait = true`
- Helm flags: `atomic = true`, `wait = true`, `cleanup_on_fail = true`

### Ingress (AWS ALB) — consumer managed

Ingress is supported as a configuration block that maps to the chart’s ingress
values.

- `hostname` (string, optional; required when ingress is enabled): public hostname
- `ingress` (object, optional; default `{}`):
  - `enabled` (optional(bool), default `true`)
  - `annotations` (optional(map(string)), default `{}`): for AWS ALB ingress annotations (scheme, target-type, listen-ports, etc.)
  - `path` (optional(string), default `"/"`)
  - `path_type` (optional(string), default `"Prefix"`)
  - `tls_secret_name` (optional(string), default `null`)

Explicit Helm values mapping (Argo CD chart `server.ingress.*`):

- `ingress.enabled` → `server.ingress.enabled`
- (fixed) → `server.ingress.controller = "aws"` (module sets this to match the AWS ALB ingress intent)
- (fixed) → `server.ingress.ingressClassName = "alb"` (module sets this to match the AWS ALB ingress intent)
- `ingress.annotations` → `server.ingress.annotations`
- `hostname` → `server.ingress.hostname` (only when `ingress.enabled = true`)
- `ingress.path` → `server.ingress.path`
- `ingress.path_type` → `server.ingress.pathType`
- `ingress.tls_secret_name` → `server.ingress.extraTls[0].hosts[0]=hostname` and `server.ingress.extraTls[0].secretName=tls_secret_name` (only when `tls_secret_name` is non-null)

Notes / constraints:

- When `ingress.enabled = false`, hostname/path/tls settings are ignored and `ingress_hostnames` output is empty.
- The module will not assume a cert-manager flow.
- ALB typically terminates TLS at the ALB; `tls_secret_name` remains optional for
  clusters that do in-cluster termination.
- The module will not create AWS resources; it only configures Kubernetes Ingress.
- TLS behavior is expressed only via `server.ingress.extraTls` when `tls_secret_name` is set; the module does not set `server.ingress.tls`.
- This module intentionally does not use the chart’s default fixed TLS secret path (e.g. `argocd-server-tls`) and does not attempt to manage certificates.

### Admin password sourcing (Mode A)

Argo CD ships with an `admin` account. We support two mutually-exclusive modes
to set its initial password.

Inputs:

- `admin_password_bcrypt` (string, default `null`, sensitive): **bcrypt hash** of the desired admin password (not plaintext). If set, Helm manages `argocd-secret` and Terraform passes the bcrypt via chart values.
- `use_existing_admin_secret` (bool, default `false`): when true, Terraform does not manage admin password material and expects an existing `argocd-secret` in the target namespace with `admin.password` / `admin.passwordMtime` already set.

Contract:

- Set **exactly one** of `admin_password_bcrypt` or `use_existing_admin_secret = true`.
- Enforce with `lifecycle.precondition` on the Helm release.

Secret contract (matches upstream chart template):

- Secret name is fixed: `argocd-secret` in `var.namespace`
- Keys when Helm manages the admin password (via chart values):
  - `admin.password`: populated from `configs.secret.argocdServerAdminPassword`
  - `admin.passwordMtime`: populated from `configs.secret.argocdServerAdminPasswordMtime` (left empty to use chart default of “now” on updates)

Security note:

- `admin_password_bcrypt` is still credential material and will be stored in Terraform state (as a sensitive value). Prefer `use_existing_admin_secret = true` with an ExternalSecret/Secrets Manager–backed `argocd-secret` for production.
- In `use_existing_admin_secret = true` mode, installs/upgrades will fail if `argocd-secret` does not exist in the namespace at apply time.

## Values Strategy (No Pass-through)

The module constructs a minimal chart values map in `locals` and applies it via
`yamlencode(...)` (or `jsonencode` where consistent with chart requirements),
similar to `modules/keycloak`.

Only the following will be configured initially:

- `server.ingress.*` (hostname/path/class/annotations + optional TLS)
- `configs.secret.createSecret`:
  - `true` when `admin_password_bcrypt` is set (Helm manages `argocd-secret`)
  - `false` when `use_existing_admin_secret = true` (consumer manages `argocd-secret`)
- basic metadata/labels if needed for consumer integration (kept minimal)

Anything beyond this requires an intentional module change (wrapper expansion).

## Resources

Expected resources (subject to the chart’s exact secret wiring):

- `kubernetes_namespace_v1.this` (optional, when `create_namespace = true`)
- `helm_release.this`

## Outputs

- `release_name`
- `release_namespace`
- `release_status`
- `release_chart_version`
- `helm_metadata`
- `admin_password_secret_name` (resolved name)
- `ingress_hostnames` (list; `[var.hostname]` when ingress enabled, otherwise `[]`)

## Example(s)

Add `modules/argocd/examples/basic/` showing:

- AWS ALB ingress usage with placeholder annotations
- `use_existing_admin_secret = true` mode (preferred example to avoid password material in Terraform inputs/state)

## Validation / Housekeeping Alignment

To classify as a maintained module, the new module must include:

- `README.md` with human-written preamble + terraform-docs block
- `versions.tf` with Terraform ~> 1.3 and provider constraints
- `providers.tf` (when needed to keep provider config patterns consistent with other maintained modules)
- `main.tf`, `variables.tf`, `outputs.tf`
- `examples/basic/` scaffold

If tests are not added initially, record it as an expected baseline exception
only if required by housekeeping; otherwise align with the common pattern of
example-based validation.

## Open Questions (deferred unless they block implementation)

- Should the default `chart_version` be periodically bumped by maintenance automation, or only by explicit changes?
