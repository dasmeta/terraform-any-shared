# Implementation Plan: Shared CloudNativePG cluster module

**Branch**: `012-add-cnpg-module` | **Date**: 2026-08-05 | **Spec**: [spec.md](spec.md)
**Input**: Address PR review feedback by making the new module cluster-only.

## Current State and Review Gap

`modules/cnpg` currently creates a Cluster plus an optional native Barman Cloud
backup and ScheduledBackup. Review found missing grouped-field comments,
incomplete planning evidence, incomplete pre-commit coverage, generated
example/test README files, several input-validation gaps, and use of deprecated
CNPG backup and PodMonitor capabilities.

This revision narrows the module to one Cluster with one initial database and
owner. It removes the unreleaseable backup, backup-schedule, and PodMonitor
interfaces before the first release; therefore there is no downstream breaking
change.

## Technical Context

- **Terraform**: `~> 1.3`
- **Provider**: `gavinbunney/kubectl ~> 1.14`
- **Module path**: `modules/cnpg`
- **Platform contract**: CNPG 1.26 or later serving `postgresql.cnpg.io/v1`.
  CNPG 1.20 is EOL and outside the supported module baseline; its upgrade is a
  cluster-owner concern.
- **Scope**: Cluster, initial database/owner, storage, HA defaults, metadata
  inheritance, and non-secret service outputs.
- **Explicit exclusions**: operator lifecycle, Secret values, monitoring CRs,
  backup plugin/ObjectStore/bucket/schedules, restores, extra roles/databases,
  grants, and application configuration.
- **Validation**: formatting, isolated init/validate, mocked Terraform tests,
  Terraform docs, Checkov, repository pre-commit, TFLint, and CI matrices.

## Governance and Speckit Evidence

- **Shared governance source**: the constitution repository's
  `terraform-module-developer` skill, internal module standards, and planning
  checklist.
- **Downstream evidence**: this active package contains `spec.md`, `plan.md`,
  and `tasks.md`; the requested implementation is the `/speckit.implement`
  continuation of feature `012-add-cnpg-module`.
- **Module-change gate**: expected to pass after this plan, task list,
  examples, tests, generated docs, and pre-commit matrix are aligned.

## Sourcing and Wrapper Preservation

- The approved AWS, Azure, and Google Terraform module collections contain no
  Kubernetes CNPG Cluster module; no DasMeta CNPG module exists.
- The upstream `cloudnative-pg/charts` `cluster` chart was considered and
  rejected: it introduces Helm-chart version coupling and a broader values
  surface than this provider-agnostic Cluster wrapper needs.
- `kubectl_manifest` is the established repository fallback for custom
  resources (`kiali`, `istio`, and `gateway-api-crds`) and avoids CRD OpenAPI
  schema discovery during Terraform plan.
- The module remains opinionated: required grouped `storage` and `database`
  objects capture the unambiguous configuration boundary; optional resources,
  labels, annotations, PostgreSQL parameters, and affinity policy retain safe
  defaults. No raw manifest or arbitrary CNPG-field pass-through is exposed.
- The fallback scratch-template source was reviewed for file coverage only;
  the repository's established module layout, tests, and automation take
  precedence.

## Modern Capabilities Classification

| Net-new ability | Classification | Evidence and decision |
| --- | --- | --- |
| CNPG Cluster, initdb, managed owner role, storage, and inherited metadata | supported | The stable `postgresql.cnpg.io/v1` Cluster API is used. |
| Native `backup.barmanObjectStore`, retention, and ScheduledBackup | replaced / out of scope | CNPG 1.26 deprecates native Barman support and directs new deployments to the Barman Cloud plugin/ObjectStore. Plugin installation and ObjectStore ownership are separate platform scope, so this module omits backup rather than creating a deprecated contract. |
| `monitoring.enablePodMonitor` | replaced / out of scope | CNPG 1.26 deprecates it; owning a manually created PodMonitor is a separate monitoring module responsibility. |

Sources: [CNPG 1.26 release notes](https://cloudnative-pg.io/docs/1.26/release_notes/v1.26/), [Barman Cloud migration guide](https://cloudnative-pg.io/plugin-barman-cloud/docs/migration/), and [CNPG supported releases](https://cloudnative-pg.io/docs/1.26/supported_releases/).

## Proposed File Changes

- `modules/cnpg/{main,variables,outputs,README}.tf`: remove deprecated
  interfaces, enforce SCRAM, use a published multi-architecture image digest,
  propagate inherited metadata, add read-only Service outputs, and document
  readiness/role limitations.
- `modules/cnpg/locals.tf`: remove because backup composition is out of scope.
- `modules/cnpg/examples/basic` and `modules/cnpg/tests/basic`: add generated
  README files and align usage with the cluster-only interface.
- `modules/cnpg/tests/invalid_inputs.tftest.hcl`: cover identifiers, storage
  quantities, inherited metadata, and deterministic outputs.
- `.github/workflows/pre-commit.yaml`: register `modules/cnpg`.
- `AGENTS.md`: record the actual CNPG/Kubectl module technology and change.
- Speckit evidence: synchronize spec, research, contract, data model,
  quickstart, and task completion evidence.

## Interface and Risk Assessment

- **Breaking changes**: none. The removed backup and PodMonitor inputs are
  unreleased and have no consumers.
- **Interface widening**: read-only Service outputs are additive, deterministic
  CNPG conventions, and do not broaden control of the underlying resource.
- **Conflict requiring approval**: none. The user explicitly approved the
  cluster-only scope after the review identified deprecated backup behavior.

## Structure

```text
modules/cnpg/
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
├── README.md
├── examples/basic/{0-setup.tf,1-example.tf,README.md}
└── tests/{basic/{main.tf,providers.tf,README.md},invalid_inputs.tftest.hcl}

specs/012-add-cnpg-module/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/module-interface.md
└── tasks.md
```
