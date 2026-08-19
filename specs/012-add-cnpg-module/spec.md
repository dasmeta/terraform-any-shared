# Feature Specification: Shared CloudNativePG cluster module

**Feature Branch**: `012-add-cnpg-module`
**Created**: 2026-08-05
**Status**: In implementation
**Input**: Create a reusable CNPG Cluster module and revise it after review to
remain cluster-only: no deprecated native backup, backup scheduling, or
PodMonitor ownership.

## Module Context

- **Target module**: `modules/cnpg`
- **Related files**: module source, README, basic example/test fixtures,
  invalid-input tests, CI matrices, and `specs/012-add-cnpg-module` evidence.
- **Baseline**: the CloudNativePG `postgresql.cnpg.io/v1` Cluster API via the
  repository's `gavinbunney/kubectl` custom-resource pattern.
- **Consumer contract**: an existing namespace and basic-auth bootstrap Secret;
  explicit instances/storage; one database/owner; non-secret service outputs.
- **Non-goals**: operator lifecycle, secret values, backup plugin/ObjectStore,
  monitoring CRs, restores, extra database roles/grants, raw manifest values,
  and application configuration.
- **Compatibility**: CNPG 1.26 or later is the supported module baseline.
  CNPG 1.20 is EOL, and any cluster upgrade belongs to the cluster owner rather
  than this module.

## User Scenarios and Testing

### User Story 1 — Provision an application database cluster (P1)

An infrastructure operator can create one CNPG Cluster in an existing
namespace, bootstrap one application database/owner from an existing Secret,
and choose explicit storage and high-availability capacity.

**Independent test**: Terraform renders one Cluster with initdb and managed
role Secret references, but contains no credential values.

**Acceptance scenarios**:

1. Given an existing CNPG operator, namespace, and same-namespace
   `kubernetes.io/basic-auth` Secret, applying the module creates one Cluster
   with the specified database and owner.
2. Given a secret manager owns the bootstrap Secret, Terraform references its
   name only and neither reads nor writes credentials.

### User Story 2 — Connect workloads safely (P2)

An application operator can use deterministic read/write, read-only, and
read-replica Service hostnames plus non-secret database identity outputs.

**Independent test**: output tests confirm all generated hostnames use the
provided namespace and Cluster name.

**Acceptance scenario**:

1. Given valid Cluster identity, consumers receive `-rw`, `-ro`, and `-r`
   endpoints without receiving a password.

### User Story 3 — Apply operational metadata (P3)

An infrastructure operator can attach labels and annotations consistently to
the Cluster and CNPG-generated resources.

**Independent test**: manifest tests confirm `spec.inheritedMetadata` contains
the supplied labels and annotations.

**Acceptance scenario**:

1. Given caller metadata, CNPG-generated Pods, Services, and PVCs inherit it
   through the Cluster's supported metadata mechanism.

## Edge Cases

- A CNPG CRD/operator is missing: Kubernetes rejects the manifest; this module
  does not install cluster-scoped components.
- The bootstrap Secret is missing or has the wrong key contract: CNPG cannot
  bootstrap; the secret-management owner remediates it.
- Storage uses a milli-byte suffix, an identifier exceeds PostgreSQL's
  63-byte limit, or a required identity is malformed: Terraform rejects it
  before contacting Kubernetes.
- The Cluster resource is created but not Ready: the dependent application must
  explicitly wait for CNPG's Ready condition.

## Requirements

- **FR-001**: Create exactly one Cluster using `postgresql.cnpg.io/v1` in an
  existing namespace.
- **FR-002**: Bootstrap exactly one database and owner from a caller-provided
  same-namespace Secret reference and maintain that owner role from the same
  reference.
- **FR-003**: Never accept, create, read, render, or output a credential value.
- **FR-004**: Require and validate Cluster identity, database identity,
  instance count, storage class, and a whole-byte positive storage quantity.
- **FR-005**: Enforce SCRAM password encryption independently of caller
  PostgreSQL parameter values.
- **FR-006**: Inherit caller labels and annotations to CNPG-generated resources.
- **FR-007**: Expose non-secret `-rw`, `-ro`, and `-r` service identity,
  database/owner, namespace, and port outputs.
- **FR-008**: Do not expose deprecated native Barman backup, ScheduledBackup,
  or PodMonitor interfaces.
- **FR-009**: Keep README, generated module docs, example/test READMEs, tests,
  Speckit evidence, and CI coverage aligned.

## Success Criteria

- A consumer can validate the documented Cluster configuration without a live
  Kubernetes cluster or any Terraform-held secret value.
- Invalid storage and identity inputs fail during Terraform validation.
- All deterministic CNPG endpoint and inherited-metadata contracts are tested.
- Local formatting, validation, Terraform tests, Terraform docs, Checkov, and
  repository pre-commit complete without modifying tracked files.
