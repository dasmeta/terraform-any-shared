# Feature Specification: SFTPGo Terraform Module

**Feature Branch**: `009-sftpgo-module`  
**Created**: 2026-07-03  
**Status**: Draft  
**Input**: User description: "Create reusable Terraform SFTPGo module for Kubernetes Helm deployment with required S3-backed user storage, sensitive Terraform variable secrets, admin and user bootstrap, persistence, ingress, resources, README, examples, tests, and Speckit evidence for DMVP-10248"

## Module Context *(mandatory)*

- **Target Module Path**: `modules/sftpgo`
- **Related Files In Scope**: `modules/sftpgo/README.md`, `modules/sftpgo/examples/basic`, `modules/sftpgo/tests/basic`, `AGENTS.md`, and this Speckit package.
- **Upstream Baseline**: SFTPGo Helm chart from the upstream SFTPGo chart repository.
- **Requested Interface Change**: Add a new opinionated module interface for SFTPGo deployment, namespace handling, Helm chart versioning, required S3-backed user storage, sensitive Terraform variable inputs for bootstrap secrets, default admin bootstrap, user bootstrap, persistence, UI ingress, resources, and useful outputs.
- **Requested Interface Extension (2026-08-17)**: Add optional SFTP-only external TCP exposure through a separate Kubernetes Service so consumers can publish the SFTP port without exposing WebUI or telemetry ports.
- **Requested Interface Extension (2026-08-17)**: Add grouped WebUI session settings so JWT/CSRF signing remains stable across restarts and browser cookie lifetime is explicit.
- **Breaking Change / Interface Widening**: The original module was new, so there was no existing consumer contract to break. The 2026-08-17 SFTP service extension is backward-compatible and disabled by default. The interface must stay narrower than the full Helm chart surface.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Deploy SFTPGo With S3 Storage (Priority: P1)

A platform engineer can consume the shared module to deploy SFTPGo into a Kubernetes namespace using the upstream Helm chart, required S3-backed user storage, sensitive Terraform variable secrets, persistence, ingress, and resource settings.

**Why this priority**: This is the core reusable deployment path and provides the minimum valuable module.

**Independent Test**: Run Terraform formatting and validation for the module and basic example, then inspect the rendered module interface to confirm the example configures SFTPGo with S3 storage without undocumented inputs.

**Acceptance Scenarios**:

1. **Given** a consumer has Kubernetes and Helm providers configured, **When** they use the basic example with S3 storage values and sensitive secret variables, **Then** Terraform validates the configuration without requiring customer-specific local files.
2. **Given** the module is configured with namespace, chart version, persistence, ingress, and resources, **When** Terraform evaluates the module, **Then** the resulting Helm release values include the intended SFTPGo settings.

---

### User Story 2 - Bootstrap Admin And Users (Priority: P2)

A platform engineer can configure default admin bootstrap and SFTP user bootstrap through the module without copying environment-specific sidecar logic into each consumer repository.

**Why this priority**: Bootstrap support is required for repeatable SFTPGo setup and avoids manual post-install user configuration.

**Independent Test**: Validate the module with bootstrap admin and user input objects and confirm the generated Helm values include the bootstrap environment and sidecar configuration.

**Acceptance Scenarios**:

1. **Given** admin and user bootstrap inputs are provided, **When** Terraform evaluates the module, **Then** the Helm values include default admin creation and a user bootstrap container configured from sensitive Terraform variables.
2. **Given** one or more users are configured with S3 key prefixes, **When** the bootstrap values are generated, **Then** each user maps to the shared S3 bucket configuration and its own key prefix.

---

### User Story 3 - Consume Documented Module Contract (Priority: P3)

A platform engineer can understand and adopt the new module from repository documentation, a copy-pasteable example, and validation artifacts.

**Why this priority**: Shared modules must be self-documenting enough for safe reuse and review.

**Independent Test**: Review README, example, and test artifacts to confirm they match the final supported interface and avoid real customer names, hostnames, paths, or secrets.

**Acceptance Scenarios**:

1. **Given** a user opens the module README, **When** they follow the documented example, **Then** all required inputs and sensitive values are described with neutral placeholders.
2. **Given** a reviewer inspects examples and tests, **When** they search for customer-specific values, **Then** only neutral `example`, `test`, `demo`, or `dasmeta` naming is present.

---

### User Story 4 - Preserve WebUI Sessions (Priority: P1)

A platform engineer can configure a stable SFTPGo WebAdmin/WebClient signing
passphrase and cookie policy so routine pod restarts do not invalidate browser
sessions.

**Why this priority**: SFTPGo generates a new signing key on startup when no
passphrase is configured, which logs every browser session out after a restart.

**Independent Test**: Validate the module with a `web_session` object and inspect
the generated Helm values for the expected `config.httpd` fields.

**Acceptance Scenarios**:

1. **Given** a stable sensitive signing passphrase is configured, **When** the
   module builds Helm values, **Then** `config.httpd.signing_passphrase` is
   populated deterministically.
2. **Given** a consumer sets `cookie_lifetime` to 720, **When** SFTPGo starts,
   **Then** WebAdmin and WebClient cookies can remain valid for up to 12 hours,
   subject to SFTPGo activity refresh behavior.
3. **Given** `token_validation` is omitted, **When** values are generated, **Then**
   the module preserves SFTPGo's default same-IP token validation.

---

### Edge Cases

- Required sensitive values are omitted or empty.
- A bootstrap user omits an explicit home directory or S3 key prefix.
- Ingress is disabled for private deployments.
- SFTP TCP exposure is disabled by default while WebUI ingress remains enabled.
- Consumers need an internal network load balancer for SFTP without exposing HTTP or telemetry ports.
- Persistence requests are changed from the default size or storage class.
- Consumers attempt to pass broad arbitrary Helm values that would weaken the opinionated interface.
- The upstream chart version changes independently from the module default.
- A consumer omits `web_session`; the module must preserve the existing chart behavior and not invent a secret.
- A consumer provides an empty signing passphrase or a cookie lifetime outside SFTPGo's documented range.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The module MUST own only SFTPGo Kubernetes Helm deployment concerns.
- **FR-002**: The module MUST expose an opinionated interface for the common SFTPGo deployment path rather than the full upstream Helm chart surface.
- **FR-003**: The module MUST deploy SFTPGo through the upstream SFTPGo Helm chart.
- **FR-004**: The module MUST support namespace creation and namespace selection.
- **FR-005**: The module MUST expose chart repository and chart version inputs with safe defaults.
- **FR-006**: The module MUST require S3-backed user storage configuration for the supported bootstrap path.
- **FR-007**: Admin password, bootstrap user passwords, and S3 access secret MUST be accepted through Terraform variables marked sensitive.
- **FR-008**: The module MUST support default admin creation.
- **FR-009**: The module MUST support one or more bootstrap users with configurable usernames, passwords, key prefixes, and password-change behavior.
- **FR-010**: The module MUST support persistence, UI ingress, resources, image pull secrets, and deployment strategy configuration through grouped inputs.
- **FR-011**: The module MUST generate deterministic Helm values from the supported inputs.
- **FR-012**: The module MUST include useful outputs for the Helm release and namespace.
- **FR-013**: The module README, examples, and tests MUST match the final interface.
- **FR-014**: Terraform code, examples, tests, and documentation MUST avoid customer-specific names, hostnames, paths, and secrets.
- **FR-015**: Any validation limitation MUST be documented in the plan, README, or test notes.
- **FR-016**: The module MUST support an optional SFTP-only Kubernetes Service for external TCP exposure.
- **FR-017**: The optional SFTP Service MUST expose only the SFTP port and MUST NOT expose WebUI or telemetry ports.
- **FR-018**: The optional SFTP Service MUST be disabled by default and configurable through a grouped input.
- **FR-019**: The module MUST expose a sensitive grouped `web_session` input with a stable signing passphrase, cookie lifetime, and token validation mode.
- **FR-020**: When `web_session` is configured, the module MUST render its values under SFTPGo `config.httpd` without exposing the full upstream chart configuration surface.
- **FR-021**: The module MUST reject an empty signing passphrase and cookie lifetimes outside 1 through 720 minutes.
- **FR-022**: The default `token_validation` value MUST remain `0` so enabling stable sessions does not silently weaken IP validation.

### Compatibility & Delivery Requirements

- **CDR-001**: The target module path is `modules/sftpgo`; no external repository changes are in scope.
- **CDR-002**: The implementation MUST record the SFTPGo Helm chart as the upstream baseline before direct resource creation is considered.
- **CDR-003**: Validation MUST include Terraform formatting and validation for the module and basic example where provider availability permits.
- **CDR-004**: No migration guidance is required because this is a new module; adoption guidance belongs in README and examples.

### Key Entities *(include if feature involves data or structured configuration)*

- **SFTPGo Deployment Configuration**: Module-level name, namespace, chart, persistence, ingress, resources, and deployment defaults.
- **S3 Storage Configuration**: Bucket, region, access key, access secret, and optional endpoint/path-style settings that define user filesystem backing.
- **Admin Bootstrap Configuration**: Default admin username and sensitive password value.
- **Bootstrap User Configuration**: Usernames, sensitive passwords, S3 key prefixes, home directories, and password-change behavior.
- **Rendered Helm Values**: Deterministic values passed to the Helm release from the supported module inputs.
- **SFTP Service Configuration**: Optional Kubernetes Service settings for SFTP-only TCP exposure, including service type, port, annotations, and source ranges.
- **Web Session Configuration**: Sensitive signing passphrase plus cookie lifetime and token validation settings rendered into SFTPGo's HTTP server configuration.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Consumers can copy the basic example and see all required SFTPGo, S3, admin, and user bootstrap inputs without relying on an environment-specific example.
- **SC-002**: Terraform formatting succeeds for all files added for `modules/sftpgo`.
- **SC-003**: Terraform validation succeeds for the module and basic example, or any environment/provider limitation is explicitly documented.
- **SC-004**: README, examples, and tests use only neutral names and match the final supported interface.
- **SC-005**: The new module does not expose a broad passthrough of arbitrary low-frequency upstream Helm chart options.
- **SC-006**: Consumers can enable an SFTP-only LoadBalancer Service without changing the chart's shared internal service.
- **SC-007**: Consumers can configure a stable WebUI signing passphrase and validate the module without unsupported-argument or validation errors.
- **SC-008**: The default WebUI token validation mode remains unchanged unless explicitly configured by the consumer.
