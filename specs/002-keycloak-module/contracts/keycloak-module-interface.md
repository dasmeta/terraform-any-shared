# Contract: Keycloak Module Interface

## Purpose

Define the supported consumer-facing interface for `modules/keycloak` so the
module remains an opinionated Keycloak wrapper instead of a broad chart
pass-through.

## Contract Fields

The module contract MUST define:

- `name`
- `namespace`
- `create_namespace`
- `chart_version`
- `hostname`
- `ingress`
- `bootstrap_credentials`
- `external_database`
- stable release-oriented outputs

The contract MAY define:

- a limited replica or resources configuration block
- narrow metadata fields such as labels or annotations when they serve the
  common Keycloak deployment path

The contract MUST NOT define:

- a generic Helm values pass-through
- unrestricted `set`/`set_sensitive` style escape hatches exposed as public API
- bundled database ownership in the first version
- ingress controller, DNS, or certificate automation ownership

## Contract Rules

- The module MUST deploy Keycloak through the `codecentric/keycloakx` chart.
- The module MUST support only the external-database deployment path in the
  first maintained release.
- Existing Kubernetes Secret references MUST be documented as the preferred
  bootstrap credential path.
- Raw bootstrap credential values MUST only be supported through an explicit
  fallback path.
- If both raw values and existing Secret references are configured for the same
  credential scope, the module MUST fail validation.
- README, example, and test assets MUST use only the supported contract surface
  and MUST NOT rely on hidden chart internals.

## Review Outcomes

- `aligned`: the module exposes only the curated interface and its support
  artifacts match it
- `widened`: the module adds broad upstream exposure without recorded approval
- `invalid`: the module violates prerequisite boundaries or has ambiguous
  credential-source handling

## Non-Goals

- This contract does not promise support for the full upstream chart schema.
- This contract does not cover advanced Keycloak topologies beyond the first
  standard deployment path.
