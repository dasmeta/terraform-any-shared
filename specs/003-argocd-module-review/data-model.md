# Data Model: Argo CD module review & hardening

**Date**: 2026-04-21  
**Spec**: `spec.md`

This feature is a Terraform module wrapper; the “data model” is the structured configuration surface and its invariants.

## Entities

### ArgoCDRelease

- **Represents**: A single Argo CD Helm release deployed into a Kubernetes cluster.
- **Key attributes**:
  - `name`: release name
  - `namespace`: target namespace
  - `chart_version`: upstream chart version
  - `helm_behavior`: `{ create_namespace, atomic, cleanup_on_fail, wait, helm_timeout }`

### IngressConfig

- **Represents**: How Argo CD server is exposed via ingress.
- **Key attributes**:
  - `enabled`
  - `controller` (default `"aws"`)
  - `ingress_class_name` (default `"alb"`)
  - `hostname` (required when enabled)
  - `path`, `path_type`
  - `annotations` (ALB annotations)
  - `tls_secret_name` (optional)
- **Invariant**:
  - If `enabled=true` → `hostname` must be non-empty.

### AdminCredentialMode

- **Represents**: How admin credential material is supplied.
- **Modes**:
  - **External Secret mode**: `use_existing_admin_secret=true`
  - **Terraform bcrypt mode**: `admin_password_bcrypt` set
- **Invariant**:
  - Exactly one mode must be selected.

### ScalingConfig

- **Represents**: Resilience and resource allocation for Argo CD server.
- **Key attributes**:
  - `replicas` (default 2)
  - `resources` (requests/limits defaults)
  - `autoscaling` (optional; disabled by default)

### ExtraConfigs

- **Represents**: Consumer-provided overrides/extensions to chart values.
- **Key attributes**:
  - `extra_configs` (free-form object)
- **Invariant**:
  - Must not require widening the wrapper interface for edge values.
