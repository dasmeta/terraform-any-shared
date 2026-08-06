# Feature Specification: Shared ExternalSecret module

**Feature Branch**: `014-external-secret-module`
**Created**: 2026-08-06
**Status**: Ready for implementation

## Module Context

- **Target Module Path**: `modules/external-secret`
- **Related Files In Scope**: module README, basic example and tests, CI matrices, and this Speckit package.
- **Upstream Baseline**: No suitable module exists in the approved AWS, Azure, or Google provider-maintained collections. Render the documented External Secrets Operator resource using the repository's established Kubectl provider convention.
- **Requested Interface Change**: New narrow module with one store, one remote key, explicit property mappings, and one typed target Secret.
- **Breaking Change / Interface Widening**: None; this is a bounded new module.

## User Scenarios & Testing

### User Story 1 - Synchronize an application Secret (Priority: P1)

An infrastructure consumer maps selected properties from a provider-side secret into a Kubernetes Secret, without placing credentials in Terraform configuration or state.

**Why this priority**: Applications cannot safely start without a provider-backed target Secret.

**Independent Test**: Render two mappings and verify the ExternalSecret store, remote key, target keys, and Secret type.

**Acceptance Scenarios**:

1. **Given** an existing SecretStore and remote secret, **When** mappings are supplied, **Then** only those named properties are requested and written to the named target Secret.
2. **Given** a target Secret type, **When** the resource is rendered, **Then** the target template declares that exact type.

### User Story 2 - Bootstrap a database owner Secret (Priority: P2)

A database consumer maps `username` and `password` into a `kubernetes.io/basic-auth` Secret for database bootstrap.

**Why this priority**: Database bootstrap requires a standard Secret shape and must not rely on application-specific environment-variable names.

**Independent Test**: Render a basic-auth target and confirm its type plus both mappings.

**Acceptance Scenario**:

1. **Given** the two database properties, **When** the basic-auth type is selected, **Then** the target declares `kubernetes.io/basic-auth` and retains both key names.

### Edge Cases

- Empty mapping lists, duplicate target keys, and blank remote properties are rejected before rendering.
- Secret and SecretStore names must be valid Kubernetes DNS labels.
- Secret values, remote content, and provider credentials are never inputs, outputs, examples, tests, or documentation.

## Requirements

### Functional Requirements

- **FR-001**: The module MUST render exactly one `external-secrets.io/v1` ExternalSecret.
- **FR-002**: The module MUST accept one remote key and explicit property-to-target-key mappings; it MUST NOT accept secret values.
- **FR-003**: The module MUST support a typed target Kubernetes Secret, including `kubernetes.io/basic-auth`.
- **FR-004**: The module MUST refer to an existing SecretStore or ClusterSecretStore and MUST NOT create credentials, IAM resources, or the External Secrets Operator.
- **FR-005**: The module MUST use the supported v1 API and documented target template type field.
- **FR-006**: The module MUST validate names, mapping contents, refresh intervals, and lifecycle-policy values.
- **FR-007**: The README, example, tests, generated documentation, and workflow matrices MUST match the final interface.

### Compatibility & Delivery Requirements

- **CDR-001**: The module MUST remain compatible with Terraform `~> 1.3` and the existing Gavinbunney Kubectl provider convention.
- **CDR-002**: The module requires an installed External Secrets Operator v1 CRD and existing SecretStore.
- **CDR-003**: Formatting, Terraform tests, terraform-docs, Checkov, and repository CI matrices MUST pass before publication.

### Key Entities

- **Secret store reference**: Existing SecretStore or ClusterSecretStore used for retrieval.
- **Target Secret**: Named Kubernetes Secret, its type, and bounded lifecycle policies.
- **Mapping**: One Kubernetes Secret key paired with one property under the common remote key.

## Success Criteria

- **SC-001**: Consumers can render application and basic-auth Secrets with zero credential values in Terraform inputs or outputs.
- **SC-002**: The basic fixture verifies store, remote key, mappings, target name, type, and lifecycle policies.
- **SC-003**: Module-local checks complete with zero failed Terraform tests and zero Checkov findings.
- **SC-004**: The README example has no undocumented operator, SecretStore, or provider prerequisite.
