# Phase 0 Research: Keycloak Helm Wrapper Module

## Decision 1: Use the `codecentric/keycloakx` Helm chart as the only deployment baseline

**Decision**: Build the new module as an opinionated wrapper around the
`codecentric/keycloakx` Helm chart and do not plan a direct Kubernetes-resource
implementation path for the first version.

**Rationale**: The feature spec explicitly names `codecentric/keycloakx` as the
upstream baseline, and the repository constitution prefers wrapping a
provider-maintained chart before recreating equivalent behavior directly. This
keeps the module aligned with existing Helm-wrapper patterns in the repository.

**Alternatives considered**:
- Deploy Keycloak from raw Kubernetes resources:
  rejected because it would ignore the requested upstream baseline and create a
  larger maintenance surface.
- Introduce a dual-mode chart-or-resources implementation:
  rejected because it would widen scope without solving a current requirement.

## Decision 2: Keep the first-version interface curated and task-oriented

**Decision**: Expose only first-class inputs that map to the common Keycloak
deployment path: release identity, namespace handling, chart version pinning,
replica/resources basics, hostname and ingress settings, bootstrap credential
selection, and external database connectivity. Do not include a generic Helm
values pass-through.

**Rationale**: The spec and constitution both require an opinionated wrapper
instead of a broad chart mirror. A narrow interface keeps the module reviewable
and avoids turning `modules/keycloak` into another place consumers must learn
the full upstream values schema.

**Alternatives considered**:
- Expose `values`, `custom_values`, or `set` escape hatches:
  rejected because they undermine the wrapper boundary in the first release.
- Mirror most upstream chart options as Terraform variables:
  rejected because it increases maintenance cost without improving the common
  deployment path.

## Decision 3: Treat external database, ingress controller, DNS, TLS, and secret backends as prerequisites

**Decision**: The first version will support only consumer-managed external
database connectivity and application-facing ingress/hostname configuration.
The module will not provision the database, ingress controller, DNS records,
certificate issuance, or an external secret backend.

**Rationale**: This matches the clarified feature scope and keeps the module
inside one coherent responsibility boundary: deploying the Keycloak workload
through Helm. It also aligns with how other repository modules assume an
already-available Kubernetes environment and adjacent platform services.

**Alternatives considered**:
- Add bundled database support:
  rejected because the clarified spec explicitly excludes it from the first
  supported mode.
- Manage ingress controller or certificate resources:
  rejected because that would cross the module boundary into adjacent platform
  infrastructure.

## Decision 4: Prefer consumer-managed secret references, with a controlled raw-value fallback

**Decision**: Support two bootstrap-credential paths:
1. preferred path: consumer-managed existing Kubernetes Secret references
2. fallback path: raw secret values supplied to the module and materialized into
   a module-managed Kubernetes Secret only when no existing secret reference is
   configured for that credential scope

If both paths are configured for the same credential scope, the module should
fail validation rather than silently mixing sources.

**Rationale**: Existing secret references are safer for ongoing operations and
fit better with real platform ownership boundaries. Raw values still provide a
supported bootstrap path for simpler environments, but keeping that path behind
explicit selection avoids ambiguity and hidden precedence rules.

**Alternatives considered**:
- Support only raw values:
  rejected because the spec explicitly requires existing secret references too.
- Support only existing secret references:
  rejected because the spec explicitly requires a raw-value path too.
- Silently prefer one source when both are set:
  rejected because it makes conflicting input harder to review and debug.

## Decision 5: Include the new module in maintained-module workflow matrices

**Decision**: Plan workflow updates so `modules/keycloak` is added to
`.github/workflows/checkov.yaml`, `.github/workflows/tflint.yaml`, and
`.github/workflows/terraform-test.yaml`, assuming the implementation delivers
the planned example/test scaffolding.

**Rationale**: The feature spec treats documentation and validation as part of
the deliverable. The repository’s housekeeping docs already define maintained
module workflow coverage as part of the review baseline for comparable modules.

**Alternatives considered**:
- Defer workflow inclusion until a later follow-up:
  rejected because it would leave the new maintained module below the stated
  quality bar at the moment it is introduced.
- Add only static checks and skip `terraform-test`:
  rejected because the module scope already includes runnable example/test
  paths and the spec expects them.

## Decision 6: Expose release-oriented outputs instead of deep runtime internals

**Decision**: The first version should output release metadata that helps
downstream consumers and operators identify what was deployed, such as release
name, namespace, chart version or Helm metadata, deployment status, and any
selected bootstrap Secret name or ingress host data that remains stable and
useful.

**Rationale**: The spec asks for useful outputs while the constitution cautions
against widening the interface. Release-oriented outputs are consistent with
other maintained Helm modules and avoid exposing unstable chart internals as
module API.

**Alternatives considered**:
- No outputs:
  rejected because the spec explicitly requires useful downstream outputs.
- Expose broad rendered chart internals:
  rejected because that would create unnecessary interface surface area.
