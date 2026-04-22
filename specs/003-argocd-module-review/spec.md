# Feature Specification: Argo CD module review & hardening

**Feature Branch**: `[feat/argocd-module-review]`  
**Created**: 2026-04-21  
**Status**: Draft  
**Input**: User description: "/speckit-specify we have need to create argo-cd setup terraform submodule based on helm chart, we already created it, but want to go through it and clarify/review/fix/change if neded"

## Module Context *(mandatory)*

- **Target Module Path**: `modules/argocd`
- **Related Files In Scope**:
  - `modules/argocd/main.tf`
  - `modules/argocd/variables.tf`
  - `modules/argocd/outputs.tf`
  - `modules/argocd/versions.tf`
  - `modules/argocd/README.md`
  - `modules/argocd/examples/basic/*`
- **Upstream Baseline**: `argoproj/argo-cd` Helm chart (Argo Helm)
- **Requested Interface Change**:
  - keep opinionated wrapper scope (common-case Argo CD install + ALB ingress)
  - make common settings configurable with safe defaults (ingress, namespace creation, helm behaviors)
  - add an escape hatch for unsupported chart values (`extra_configs`)
  - ensure production-friendly defaults (multi-replica, resource defaults, optional autoscaling)
  - remove unnecessary provider/resource coupling where Helm can cover it
- **Breaking Change / Interface Widening**: None expected (defaults and options added; existing inputs remain supported)

## Clarifications

### Session 2026-04-21

- Q: TLS termination + `server.insecure` default → A: Default `configs.params["server.insecure"]="true"` whenever `ingress.enabled=true`.
- Q: When autoscaling is enabled, what should `replicas` do? → A: Always set `server.replicas` from `replicas` (even if autoscaling enabled).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Deploy Argo CD with ALB ingress (Priority: P1)

An infra engineer deploys Argo CD into an existing cluster via Terraform, enabling ALB ingress and a hostname, and can reach the Argo CD UI without manual post-install patches.

**Why this priority**: This is the core value of the module: a repeatable, opinionated “common path” deployment.

**Independent Test**: Apply the module using the provided example and confirm the Argo CD server is reachable through the ingress endpoint.

**Acceptance Scenarios**:

1. **Given** a reachable Kubernetes cluster and Helm connectivity, **When** the module is applied with ingress enabled and a hostname, **Then** Argo CD server is deployed and an ingress rule exists for that hostname.
2. **Given** ALB terminates TLS, **When** a user opens the hostname via a browser, **Then** the UI loads without redirect loops or repeated redirects.

---

### User Story 2 - Choose admin credential management mode (Priority: P2)

An infra engineer chooses how admin credentials are managed: either by supplying a bcrypt hash in Terraform (bootstrap) or by relying on an externally managed Kubernetes secret (recommended).

**Why this priority**: Credential handling is required for first login and has security implications for production.

**Independent Test**: Confirm the module enforces exactly one mode and that Argo CD starts without manual secret edits.

**Acceptance Scenarios**:

1. **Given** `use_existing_admin_secret=true`, **When** the module is applied, **Then** it does not attempt to create/manage admin password material.
2. **Given** `admin_password_bcrypt` is set, **When** the module is applied, **Then** Argo CD is configured with that admin password material.
3. **Given** both modes are set or both are unset, **When** the module is planned/applied, **Then** it fails fast with a clear validation error.

---

### User Story 3 - Override advanced chart values (Priority: P3)

An infra engineer needs to set an upstream chart option that is not part of the wrapper’s narrow interface and can do so without forking the module.

**Why this priority**: Keeps the wrapper opinionated while still supporting real-world edge needs.

**Independent Test**: Provide `extra_configs` to add/override a value and confirm the rendered release picks it up.

**Acceptance Scenarios**:

1. **Given** `extra_configs` is provided, **When** the module is applied, **Then** the chart values reflect those overrides without breaking the common-case defaults.

---

### Edge Cases

- Ingress enabled but `hostname` omitted → fail fast with a clear error.
- Ingress disabled → module still deploys without requiring hostname.
- Autoscaling enabled → replicas setting does not prevent successful deployment (chart should prefer HPA behavior).
- Consumer overrides defaults via `extra_configs` → module remains usable without requiring code changes.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Module MUST deploy Argo CD via the upstream Helm chart into a target namespace.
- **FR-002**: Module MUST support ALB ingress configuration with safe defaults and allow overrides for common ingress fields (including ingress class/controller).
- **FR-003**: If ingress is enabled, module MUST require a non-empty `hostname`.
- **FR-004**: Module MUST enforce exactly one admin credential mode: bcrypt hash OR externally managed secret.
- **FR-005**: Module MUST allow consumers to pass additional upstream chart values via `extra_configs`.
- **FR-006**: Module MUST expose Helm release safety behaviors (`atomic`, `wait`, `cleanup_on_fail`) as inputs with defaults.
- **FR-007**: Module MUST support multi-replica server setup by default and allow overriding replica count.
- **FR-008**: Module MUST allow configuring resource requests/limits with sensible defaults.
- **FR-009**: Module MUST support enabling server autoscaling (HPA) via module inputs, default disabled, while still rendering a configured `server.replicas` value.
- **FR-010**: Module MUST avoid unnecessary provider/resource coupling when Helm provides an equivalent capability (e.g., namespace creation).
- **FR-011**: When ingress is enabled, module MUST default Argo CD server to run insecure behind the ALB to avoid redirect loops (`server.insecure=true`).

### Compatibility & Delivery Requirements

- **CDR-001**: The module MUST remain compatible with Terraform `~> 1.3` and Helm provider `~> 2.0`.
- **CDR-002**: Module docs MUST not include client-specific hostnames or identifiers; examples must use placeholders.
- **CDR-003**: Any interface change MUST update `README.md` and `examples/basic`.
- **CDR-004**: The module SHOULD remain a narrow wrapper (no broad “pass all values” input beyond `extra_configs`).

### Key Entities *(include if feature involves data or structured configuration)*

- **Ingress Configuration**: The set of inputs that define how Argo CD is exposed (host routing, paths, annotations, TLS secret reference).
- **Admin Credential Mode**: The consumer choice for how admin password material is managed.
- **Extra Config Overrides**: Consumer-supplied chart values that override or extend module defaults.
- **Scaling Configuration**: Replica count, resources, and optional autoscaling settings for the server workload.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Consumers can deploy Argo CD in a new cluster using `examples/basic` without post-install manual patches.
- **SC-002**: Ingress-enabled deployments have a deterministic hostname requirement and fail early when misconfigured.
- **SC-003**: The module supports both admin credential modes with clear validation and documentation.
- **SC-004**: Consumers can enable autoscaling without modifying module source.
