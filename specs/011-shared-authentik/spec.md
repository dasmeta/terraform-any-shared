# Feature Specification: Shared Authentik deployment module

**Feature Branch**: `011-shared-authentik`
**Created**: 2026-07-29
**Status**: Draft
**Input**: Implement the shared Authentik prerequisite for the reusable data
analytics platform. It must use the official chart, an externally provisioned
PostgreSQL database, and a pre-existing Kubernetes Secret. Namespace and
Authentik belong in `terraform-any-shared`; ingress and customer hosts do not.

## Module Context *(mandatory)*

- **Target Module Path**: `modules/authentik`
- **Related Files In Scope**: module source, `README.md`, `examples/basic`,
  `tests/basic`, and the Terraform test workflow matrix.
- **Upstream Baseline**: official Authentik Helm chart from
  `https://charts.goauthentik.io`; no provider-maintained Terraform module was
  found for Authentik, so this is a narrow direct Helm release wrapper.
- **Requested Interface Change**: new module inputs for namespace, release
  name, chart version, external PostgreSQL connection metadata, and the name
  of a pre-existing Authentik configuration Secret. Outputs expose the release
  and internal HTTP service contract for a separately managed ingress module.
- **Breaking Change / Interface Widening**: none; this is a new module. The
  module intentionally does not expose arbitrary Helm values, ingress,
  database provisioning, Secret creation, or Authentik tenant configuration.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Deploy Authentik against an existing database (Priority: P1)

An infrastructure operator can deploy a dedicated Authentik instance into an
already-created namespace, backed by an already-provisioned PostgreSQL database
and a Kubernetes Secret managed outside Terraform.

**Why this priority**: Central authentication is a platform prerequisite and
must not create a second database or leak credentials into Terraform state.

**Independent Test**: Terraform validation and a Helm template render show that
the official chart is pinned, its bundled PostgreSQL is disabled, the external
database metadata is passed, and the chart references the supplied Secret.

**Acceptance Scenarios**:

1. **Given** an existing namespace, PostgreSQL service, database, user, and
   configuration Secret, **When** the module is applied, **Then** it creates
   the Authentik Helm release without creating a namespace, database, user,
   credential, ingress, or bundled PostgreSQL release.
2. **Given** the chart configuration Secret contains the required Authentik
   environment-variable keys, **When** the release is rendered, **Then** both
   server and worker obtain configuration only through that existing Secret.

---

### User Story 2 - Connect a separately managed ingress (Priority: P2)

An infrastructure operator can configure the cluster's standard ingress module
without guessing the Authentik service name or port.

**Why this priority**: Shared ingress is a separate responsibility, while the
service endpoint is needed to publish Authentik safely.

**Independent Test**: The module example and test expose a deterministic
internal Service name and HTTP port derived from the release contract.

**Acceptance Scenarios**:

1. **Given** a successful module plan, **When** an operator reads its outputs,
   **Then** they receive the server Service name and HTTP port suitable for a
   separate ingress configuration.

---

### User Story 3 - Upgrade deliberately (Priority: P3)

An operator can select an approved chart version while the module prevents
unbounded or accidental resource configuration.

**Why this priority**: Authentik releases can carry database migration changes;
the platform should make chart version choices explicit and reviewable.

**Independent Test**: The module accepts a version string and uses Helm's
atomic, cleanup-on-failure, and wait behavior with a documented timeout.

**Acceptance Scenarios**:

1. **Given** an approved Authentik chart version, **When** the version input is
   changed, **Then** Terraform plans an in-place Helm release upgrade rather
   than changing the module's ownership boundaries.

### Edge Cases

- The configuration Secret does not exist or lacks `AUTHENTIK_SECRET_KEY` or
  `AUTHENTIK_POSTGRESQL__PASSWORD`: Helm deployment fails; this module must
  document the contract but must not create or read the Secret value.
- A database endpoint is not reachable or its database/user/grants are absent:
  Authentik startup fails; remediation is with the external database owner.
- An operator requests ingress, arbitrary Helm values, SMTP, blueprints,
  outposts, or lifecycle customisation: those are deliberately out of v1 scope
  and require a separately reviewed module extension.
- The release name is too long to form the chart's `-server` Service name: the
  module rejects it before apply.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The module MUST deploy only the official Authentik Helm release
  into a pre-existing namespace.
- **FR-002**: The module MUST disable the chart's bundled PostgreSQL and use
  supplied external PostgreSQL host, port, database name, and username.
- **FR-003**: The module MUST require the name of an existing configuration
  Secret, configure the chart to use it, and never accept, create, read, or
  output secret values.
- **FR-004**: The Secret contract MUST require `AUTHENTIK_SECRET_KEY` and
  `AUTHENTIK_POSTGRESQL__PASSWORD`; no customer-specific values or names may
  appear in module artifacts.
- **FR-005**: The module MUST use the official chart repository, a pinned
  default chart version, atomic Helm operations, cleanup on failed install,
  readiness waiting, and a documented timeout.
- **FR-006**: The module MUST set a stable chart fullname from the release name
  and expose the corresponding internal server Service name and HTTP port.
- **FR-007**: The module MUST not own namespace creation, ingress, database
  infrastructure, database content/users/grants, Secrets, Authentik flows,
  providers, applications, users, groups, or tenant configuration.
- **FR-008**: Module documentation, examples, tests, and the workflow matrix
  MUST match the implemented interface.

### Compatibility & Delivery Requirements

- **CDR-001**: The provider constraints MUST use the repository convention:
  Terraform `~> 1.3` and Helm provider `~> 3.0` in `versions.tf`.
- **CDR-002**: The change MUST pass formatting, isolated Terraform init and
  validate, Helm render checks, and the repository's static-analysis workflow
  when available.
- **CDR-003**: A database owner must create the database/user/grants and a
  secret manager integration must create the configuration Secret before
  applying this module.

### Key Entities *(include if feature involves data or structured configuration)*

- **External database connection**: non-secret PostgreSQL host, port, database
  name, and username passed to Authentik's chart configuration.
- **Configuration Secret reference**: a Secret name in the target namespace;
  it holds Authentik's application secret and the external database password.
- **Release endpoint**: the deterministic server Service name and HTTP port
  that a separately owned ingress module can reference.

## Success Criteria *(mandatory)*

### Measurable Outcomes

**SC-001**: A consumer can prepare the documented external database and Secret,
then plan the module without any secret value in Terraform input or output.
**SC-002**: Helm template rendering shows no bundled PostgreSQL and references
the configured existing Secret and external database metadata.
**SC-003**: Terraform formatting and isolated validation pass for the module
test fixture.
**SC-004**: README, example, test, and workflow coverage describe the same
strict supported interface.
