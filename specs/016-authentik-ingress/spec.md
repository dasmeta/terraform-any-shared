# Feature Specification: Optional Authentik ingress

**Feature Branch**: `016-authentik-ingress`
**Created**: 2026-08-06
**Status**: Ready for planning
**Input**: Add optional ingress configuration to the shared Authentik module.

## Module Context *(mandatory)*

- **Target Module Path**: `modules/authentik`
- **Related Files In Scope**: module source, `README.md`, `examples/basic`,
  `tests/basic`, and this feature package.
- **Upstream Baseline**: official Authentik Helm chart `2026.5.6`, which
  supports a server Ingress with hosts, TLS and annotations.
- **Requested Interface Change**: an optional typed ingress configuration that
  creates the chart-managed ingress, configures a hostname and TLS secret,
  selects an ingress class, and adds cert-manager issuer and HTTPS redirect
  annotations.
- **Breaking Change / Interface Widening**: backward-compatible widening;
  explicitly approved by the requester. Ingress remains disabled by default.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Publish Authentik securely (Priority: P1)

An infrastructure operator can enable a standard HTTPS ingress for an
Authentik deployment without writing a separate Kubernetes manifest.

**Why this priority**: An identity service must have a single, reviewed route
and certificate configuration close to the chart it exposes.

**Independent Test**: A Terraform test can inspect rendered Helm values and
confirm the enabled ingress has one hostname, a TLS secret and the requested
cert-manager issuer annotation.

**Acceptance Scenarios**:

1. **Given** ingress is enabled with a hostname, TLS secret and cluster issuer,
   **When** the module is planned, **Then** it renders a server ingress for that
   hostname, class and TLS secret.
2. **Given** ingress is enabled, **When** the chart creates the ingress,
   **Then** it requests its certificate from the configured issuer and redirects
   HTTP traffic to HTTPS.

---

### User Story 2 - Keep private deployments private (Priority: P2)

An operator who does not opt in to ingress keeps the existing ClusterIP-only
Authentik behavior.

**Why this priority**: Existing consumers must not become publicly reachable
as a side effect of upgrading the module.

**Independent Test**: The default rendered Helm values explicitly keep server
ingress disabled.

**Acceptance Scenario**:

1. **Given** a consumer omits the ingress input, **When** the module is
   planned, **Then** it creates no ingress and retains the existing service
   contract.

### Edge Cases

- Enabling ingress without a hostname, TLS secret name or certificate issuer
  must fail before Helm is invoked.
- Consumers can add non-reserved annotations, but cannot replace the module's
  certificate issuer or HTTPS redirect annotations.
- DNS records and Cloudflare credentials remain outside this module; enabling
  ingress does not create, update or delete DNS records.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The module MUST expose an optional typed ingress input and MUST
  keep ingress disabled by default.
- **FR-002**: When ingress is enabled, the module MUST require a non-empty
  hostname, TLS Secret name and cert-manager ClusterIssuer name.
- **FR-003**: When enabled, the module MUST render one server ingress using the
  configured ingress class, hostname and TLS Secret.
- **FR-004**: The rendered ingress MUST include the configured
  `cert-manager.io/cluster-issuer` annotation and force HTTPS redirects.
- **FR-005**: The module MAY accept additional ingress annotations, but its
  certificate and HTTPS redirect annotations MUST take precedence.
- **FR-006**: The module MUST retain its existing externally-managed database,
  Secret, release identity and ClusterIP service guarantees.
- **FR-007**: Documentation, examples and Terraform tests MUST cover enabled
  ingress and the default disabled behavior.

### Compatibility & Delivery Requirements

- **CDR-001**: The change must not alter behavior for consumers who omit the
  ingress input.
- **CDR-002**: Terraform formatting, isolated validation, module tests and a
  Helm render must validate both disabled and enabled ingress values.
- **CDR-003**: DNS ownership remains with a separate DasMeta Cloudflare module;
  this feature does not contain provider credentials or DNS records.

### Key Entities

- **Ingress configuration**: opt-in public-routing settings comprising enabled
  state, hostname, ingress class, TLS Secret name, certificate issuer, and
  optional non-reserved annotations.
- **Chart ingress values**: the official chart's server ingress configuration
  generated from the module input.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Existing consumers can upgrade without an ingress being created.
- **SC-002**: An enabled consumer can render a valid HTTPS ingress using only
  documented module inputs.
- **SC-003**: Terraform validation, unit tests and Helm rendering pass for the
  affected module.
- **SC-004**: The README and example show the exact supported ingress and TLS
  contract, while DNS remains explicitly separate.
