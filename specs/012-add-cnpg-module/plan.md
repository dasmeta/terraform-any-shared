# Implementation Plan: Shared CloudNativePG cluster module

**Branch**: `012-add-cnpg-module` | **Date**: 2026-08-05 | **Spec**: [spec.md](spec.md)
**Input**: Add a reusable CloudNativePG Cluster module for application workloads.

## Summary

Create `modules/cnpg`, a narrow wrapper for CloudNativePG's `Cluster` and,
when backup is configured, its `ScheduledBackup` custom resources. The module
assumes the cluster operator, namespace, bootstrap credentials, and optional
object-store credentials already exist. It renders only resource references and
never receives credentials themselves.

## Technical Context

<!--
  ACTION REQUIRED: Replace the content in this section with the technical details
  for the project. The structure here is presented in advisory capacity to guide
  the iteration process.
-->

**Terraform/OpenTofu Version**: Terraform `~> 1.3`
**Providers / Upstream Modules**: `gavinbunney/kubectl ~> 1.14`; CloudNativePG
`postgresql.cnpg.io/v1` CRD
**Target Module Path**: `modules/cnpg`
**Examples / Tests in Scope**: `examples/basic`, `tests/basic`,
`tests/invalid_inputs.tftest.hcl`
**Automation Gates**: `terraform fmt`, isolated `terraform init -backend=false`
and `terraform validate`, `terraform test`, terraform-docs, Checkov, TFLint,
and pre-commit where installed
**Target Platform**: an existing Kubernetes cluster with the CNPG operator and
the `postgresql.cnpg.io/v1` CRD
**Constraints**: no credentials in Terraform; no namespace/operator/bucket
ownership; no raw-manifest escape hatch; existing Secret references only
**Scale/Scope**: one shared module plus aligned documentation, example, tests,
and workflow matrices

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] Scope is one database-cluster lifecycle boundary: Cluster and its
      optional scheduled backup, but not the operator, namespace, credentials,
      bucket, restore execution, or application configuration.
- [x] The interface is intentionally narrow: a single database/owner, existing
      Secret references, explicit storage, and one optional backup policy.
- [x] `README.md`, `examples/basic`, `tests/basic`, invalid-input tests, and
      all module CI matrices are in scope.
- [x] `versions.tf` declares Terraform and the Kubectl provider explicitly.
- [x] This is an additive module with no migration impact. Direct custom-
      resource rendering is the documented fallback because no DasMeta or
      provider-maintained Terraform module exists.

## Research Decisions

1. **Module location**: place the capability in
   `dasmeta/terraform-any-shared/modules/cnpg`, alongside generic Kubernetes
   components. It must not be an Authentik or analytics submodule.
2. **Provider**: use `kubectl_manifest`, matching the repository's existing
   Kiali, Istio, and Gateway API CR patterns. `kubernetes_manifest` is avoided
   because it requires the Cluster CRD schema during planning.
3. **Cluster baseline**: use the installed `postgresql.cnpg.io/v1` API;
   bootstrap one database and owner from an existing `kubernetes.io/basic-auth`
   Secret with `username` and `password` keys. Manage the owner role from the
   same Secret so an approved external secret controller can rotate it.
4. **Safety defaults**: pin the currently deployed PostgreSQL 16.13 image,
   disable superuser access, enable data checksums, use required hostname
   anti-affinity, enable the PodMonitor, require storage class/size and
   instance count, and make S3-compatible recovery optional but typed.
5. **Backup lifecycle**: an optional Barman object-store configuration enables
   continuous WAL archiving, retention, and one CNPG six-field daily
   `ScheduledBackup`. Backup credentials are existing Secret references.
6. **Readiness**: `kubectl_manifest` does not wait for CNPG's Ready condition;
   the consuming rollout must explicitly wait for the Cluster Ready condition
   before deploying an application.

## Project Structure

### Documentation (this feature)

```text
specs/012-add-cnpg-module/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/module-interface.md
└── tasks.md
```

### Source Code (repository root)
<!--
  ACTION REQUIRED: Replace the placeholder tree below with the concrete module
  layout for this feature. Delete unused entries and expand the chosen
  structure with real paths. The delivered plan must not include placeholder
  labels.
-->

```text
modules/cnpg/
├── main.tf
├── locals.tf
├── variables.tf
├── outputs.tf
├── versions.tf
├── README.md
├── examples/basic/
│   ├── 0-setup.tf
│   └── 1-example.tf
└── tests/
    ├── basic/
    │   ├── main.tf
    │   └── providers.tf
    └── invalid_inputs.tftest.hcl

.github/workflows/{terraform-test,checkov,tflint}.yaml
```

**Structure Decision**: `modules/cnpg` follows the repository's generic
Kubernetes custom-resource modules. The module produces the CNPG API manifest;
the example and test fixture supply only neutral existing-Secret names.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Direct custom-resource rendering | No suitable DasMeta or provider-maintained Terraform module exists. | A generic Kubernetes manifest preserves a narrow typed interface without adding CRD schema discovery at plan time. |
