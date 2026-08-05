# Feature Specification: Shared CloudNativePG cluster module

**Feature Branch**: `012-add-cnpg-module`
**Created**: 2026-08-05
**Status**: Ready for planning
**Input**: Add a reusable CloudNativePG cluster module for Kubernetes workloads
that references an existing bootstrap credential Secret, creates a named
PostgreSQL cluster with an application database and owner, exposes only
non-secret connection outputs, and provides aligned documentation, example,
and validation coverage.

## Module Context *(mandatory)*

- **Target Module Path**: `modules/cnpg`
- **Related Files In Scope**: module source, `README.md`, `examples/basic`,
  `tests/basic`, invalid-input tests, and the Terraform test workflow matrix.
- **Upstream Baseline**: CloudNativePG `postgresql.cnpg.io/v1` Cluster API.
  No DasMeta module or provider-maintained Terraform module exists, so the
  module will use the established `gavinbunney/kubectl` manifest-resource
  convention for Kubernetes custom resources.
- **Requested Interface Change**: new module inputs for a pre-existing
  namespace and credential Secret, cluster identity, application database and
  owner, instance count, storage configuration, and optional backup endpoint;
  non-secret outputs for the primary read/write Service and database identity.
- **Breaking Change / Interface Widening**: none; this is a new module. The
  narrow interface intentionally excludes passwords, Secret creation, raw
  manifest pass-through, logical backups, monitoring configuration, and
  database role/grant lifecycle beyond the initial owner.

## User Scenarios & Testing *(mandatory)*

<!--
  IMPORTANT: User stories should be PRIORITIZED as user journeys ordered by importance.
  Each user story/journey must be INDEPENDENTLY TESTABLE - meaning if you implement just ONE of them,
  you should still have a viable MVP (Minimum Viable Product) that delivers value.

  Assign priorities (P1, P2, P3, etc.) to each story, where P1 is the most critical.
  Think of each story as a standalone slice of functionality that can be:
  - Developed independently
  - Tested independently
  - Deployed independently
  - Demonstrated to users independently
-->

### User Story 1 - Create an application PostgreSQL cluster (Priority: P1)

An infrastructure operator can provision a named CloudNativePG cluster in an
existing namespace, with a pre-created credential Secret, an initial database,
and its owner role.

**Why this priority**: This supplies the missing standard database contract
needed by Authentik and analytics workloads without embedding database or
credential ownership into those application modules.

**Independent Test**: An isolated Terraform plan validates the required
inputs and produces one Cluster manifest that references, but never reads or
creates, the supplied credential Secret.

**Acceptance Scenarios**:

1. **Given** an existing namespace, CNPG operator, and bootstrap credential
   Secret, **When** the module is applied, **Then** it creates one Cluster
   configured with the requested application database and owner.
2. **Given** the bootstrap credential Secret is managed by an ExternalSecret
   or another approved secret manager, **When** the module is planned,
   **Then** no password value is accepted, created, read, or output by
   Terraform.

---

### User Story 2 - Consume the primary database endpoint (Priority: P2)

An application operator can connect a separately managed workload to the
cluster using a deterministic read/write Service name, database name, owner,
and port.

**Why this priority**: Application modules need connection metadata while the
database module must retain all secret material outside Terraform state.

**Independent Test**: Module outputs are derived from validated cluster and
namespace inputs and contain no sensitive credential data.

**Acceptance Scenarios**:

1. **Given** a valid cluster configuration, **When** an application module
   consumes the outputs, **Then** it receives the primary read/write Service
   address and non-secret database connection identity.

---

### User Story 3 - Configure durable storage and recovery (Priority: P3)

An infrastructure operator can select explicit persistent storage and, when an
approved S3-compatible backup destination is available, configure the cluster
for continuous WAL archival.

**Why this priority**: Databases are stateful production infrastructure and
must not depend on undocumented volume or recovery defaults.

**Independent Test**: Terraform validation rejects unsafe storage and backup
reference shapes, while a valid backup configuration is represented in the
rendered Cluster manifest.

**Acceptance Scenarios**:

1. **Given** a valid persistent-volume configuration, **When** the module is
   applied, **Then** the requested storage class and capacity are assigned to
   the cluster.
2. **Given** an approved S3-compatible backup configuration and pre-existing
   credentials Secret, **When** the module is applied, **Then** it configures
   archive recovery without receiving the credential values.

---

[Add more user stories as needed, each with an assigned priority]

### Edge Cases

<!--
  ACTION REQUIRED: Replace these examples with Terraform-module-specific edge
  cases for the target module.
-->

- The CNPG operator or `postgresql.cnpg.io/v1` CRD is absent: the Kubernetes
  API rejects the manifest; the module documents this required cluster-level
  prerequisite and does not install the operator.
- The credential Secret is absent or does not contain the expected `username`
  and `password` keys: CNPG cannot bootstrap the owner; remediation belongs to
  the approved Secret-management owner.
- A requested policy, backup schedule, role, grant, or raw CNPG field is not
  part of the common contract: it requires a separately approved module
  extension rather than an arbitrary manifest pass-through.

## Requirements *(mandatory)*

<!--
  ACTION REQUIRED: The content in this section represents placeholders.
  Fill them out with the right functional requirements.
-->

### Functional Requirements

- **FR-001**: The module MUST create exactly one CloudNativePG Cluster in an
  existing namespace and MUST NOT install or configure the CNPG operator.
- **FR-002**: The module MUST bootstrap exactly one initial application
  database and owner role using a caller-provided Secret reference.
- **FR-003**: The module MUST never accept, create, read, render, or output a
  username, password, access key, or secret value.
- **FR-004**: The module MUST require explicit cluster name, namespace,
  database name, owner, credential Secret name, instance count, storage class,
  and storage capacity inputs, with validations for Kubernetes names and
  positive production-safe quantities.
- **FR-005**: The module MUST expose only non-secret connection outputs:
  namespace, cluster name, database name, owner, TCP port, and deterministic
  read/write Service name.
- **FR-006**: The module MUST support one optional, typed S3-compatible Barman
  backup configuration whose credential reference is an existing Secret; it
  MUST omit backup configuration when not supplied.
- **FR-007**: The module MUST not own namespace creation, the CNPG operator,
  credentials, backup bucket creation, backup scheduling, restore execution,
  extra databases, extra roles, grants, raw manifest injection, or application
  configuration.
- **FR-008**: Module documentation, example, tests, and workflow coverage MUST
  match the implemented interface.

### Compatibility & Delivery Requirements

- **CDR-001**: Provider constraints MUST use Terraform `~> 1.3` and
  `gavinbunney/kubectl ~> 1.14` in `versions.tf`.
- **CDR-002**: The change MUST pass formatting, isolated Terraform init and
  validation, Terraform test with a mocked Kubernetes provider, and available
  repository static-analysis gates.
- **CDR-003**: The README MUST state that consumers install CNPG separately,
  create the namespace and credential Secret first, and choose retention,
  backups, recovery testing, monitoring, and alerting according to their
  operational policy.

### Key Entities *(include if feature involves data or structured configuration)*

- **Cluster identity**: validated namespace and Cluster name that determine
  the Kubernetes resource and read/write Service name.
- **Bootstrap identity**: application database, owner role, and existing
  credentials Secret reference; the role/Secret values themselves are never
  handled by Terraform.
- **Storage and recovery**: requested instance count, storage class/capacity,
  and optional object-store endpoint with an existing credential Secret.
- **Connection contract**: deterministic, non-secret metadata consumed by a
  separately managed application or secret-sync component.

## Success Criteria *(mandatory)*

<!--
  ACTION REQUIRED: Define measurable success criteria.
  These must be technology-agnostic and measurable.
-->

### Measurable Outcomes

- **SC-001**: A consumer can create a database cluster from the documented
  example using only pre-existing namespace, operator, and Secret prerequisites.
- **SC-002**: All invalid bootstrap, storage, and backup reference inputs fail
  Terraform validation before contacting a Kubernetes cluster.
- **SC-003**: The module's isolated Terraform validation and mocked-resource
  tests pass without requiring a live Kubernetes cluster.
- **SC-004**: README, example, test, and generated documentation enumerate the
  same non-secret input and output contract.
