# Feature Specification: Helm-Based Ephemeral Helm Cleanup Module

**Feature Branch**: `008-ephemeral-cleanup-cronjob`
**Created**: 2026-06-11
**Status**: Implemented
**Input**: Convert the cleanup deployment into a reusable Terraform module that uses DasMeta `base-cronjob` Helm chart and can be applied for different clients with configurable schedule and related settings.

## Scope

Build a Terraform module at `modules/ephemeral-cleanup-cronjob` that installs the ephemeral Helm cleanup CronJob through the DasMeta `base-cronjob` Helm chart instead of creating Kubernetes resources directly through the Kubernetes Terraform provider.

Depend on the matching `/Users/juliaaghamyan/Desktop/dasmeta/helm/charts/base-cronjob` chart change so the chart can represent the previous YAML behavior:

- ServiceAccount for the job
- script ConfigMap mounted as files
- CronJob schedule and common job controls
- cluster-wide RBAC for Helm cleanup permissions

## Module Context *(mandatory)*

- **Target Module Path**: `modules/ephemeral-cleanup-cronjob`
- **Related Files In Scope**: `modules/ephemeral-cleanup-cronjob/main.tf`, `locals.tf`, `variables.tf`, `versions.tf`, `outputs.tf`, `README.md`, `examples/basic/main.tf`, `scripts/ephemeral-helm-cleanup.sh`, `tests/ephemeral-helm-cleanup-test.sh`
- **Upstream Baseline**: DasMeta Helm chart `base-cronjob`
- **Requested Interface Change**: New reusable Terraform module wrapping `base-cronjob` for the ephemeral Helm cleanup CronJob
- **Breaking Change / Interface Widening**: New module, so no existing module consumers are broken. The module includes bounded escape hatches through `extra_job_values` and `extra_values`.

## User Stories

### Story 1 - Reuse Cleanup Job For Different Clients

As an infrastructure operator, I want a Terraform module that installs the cleanup job with configurable namespace, schedule, namespace match pattern, and image settings so I can reuse the same cleanup behavior across multiple client clusters.

**Acceptance Criteria**

1. Given a consumer uses the module with defaults, Terraform configures one Helm release for the `base-cronjob` chart.
2. Given a consumer sets `schedule`, the rendered CronJob uses that schedule.
3. Given a consumer sets `namespace_name_pattern`, the cleanup container receives `NAMESPACE_NAME_PATTERN` with that value.
4. Given a consumer sets `dry_run = true`, the cleanup script is called with `--dry-run`.

### Story 2 - Preserve Existing Cleanup Permissions

As an infrastructure operator, I want the Helm chart to create the RBAC required by the cleanup job so Helm release cleanup can work across matched namespaces.

**Acceptance Criteria**

1. Given default module RBAC settings, the chart renders a ClusterRole and ClusterRoleBinding.
2. Given custom `rbac.rules`, the chart uses the provided rules instead of module defaults.
3. Given `rbac.cluster_wide = false`, the chart can render namespace-scoped Role and RoleBinding.

### Story 3 - Mount Script ConfigMap Without Env Import

As an infrastructure operator, I want the cleanup script stored in a ConfigMap and mounted into the container without importing that ConfigMap as environment variables.

**Acceptance Criteria**

1. Given the module renders Helm values, `config.enabled` is true and contains `ephemeral-helm-cleanup.sh`.
2. Given the module renders Helm values, `config.envFrom` is false.
3. Given Helm renders the chart, the ConfigMap is mounted at `/scripts` with read-only mode and no unwanted `envFrom` entry for the script ConfigMap.

## Functional Requirements

- FR-001: The module must use the Helm provider and a single `helm_release`.
- FR-002: The module must default to `base-cronjob` from `https://dasmeta.github.io/helm`.
- FR-003: The module must support local chart-path development by allowing `chart_repository = null` and `chart_version = null`.
- FR-004: The module must expose schedule configuration through `schedule`.
- FR-005: The module must expose namespace matching through `namespace_name_pattern`.
- FR-006: The module must expose Helm release and job names separately through `release_name` and `job_name`.
- FR-007: The module must mount `scripts/ephemeral-helm-cleanup.sh` through chart values.
- FR-008: The module must enable a chart-managed ServiceAccount by default.
- FR-009: The module must enable cleanup RBAC by default using ClusterRole and ClusterRoleBinding.
- FR-010: The module must expose common CronJob controls: concurrency policy, suspend, history limits, starting deadline, job backoff limit, finished-job TTL, restart policy.
- FR-011: The module must expose common pod controls: image settings, resources, node selector, tolerations, labels, pod annotations.
- FR-012: The module must document the chart publication dependency for version `0.1.39`.

### Compatibility & Delivery Requirements

- CDR-001: The Speckit package must live under repository root `specs/008-ephemeral-cleanup-cronjob`.
- CDR-002: The implementation must live under `modules/ephemeral-cleanup-cronjob`.
- CDR-003: Delivery must include validation evidence from `terraform fmt`, module `terraform validate`, example `terraform validate`, and the shell dry-run behavior test.
- CDR-004: The module README must explain local chart path usage until `base-cronjob` `0.1.39` is published.

## Non-Goals

- Do not create a broad pass-through for every `base-cronjob` chart value.
- Do not include legacy standalone Kubernetes YAML manifests in the module.
- Do not change the cleanup shell script behavior except preserving test coverage.
- Do not publish the Helm chart package from this repository.

## Assumptions

- Consumers have a configured Helm provider with Kubernetes cluster access.
- The cleanup image includes both `kubectl` and `helm`.
- The chart version `0.1.39` will be published before remote consumers use the default module settings.
- Existing Terraform state for direct Kubernetes resources will require migration or replacement because the implementation changed to `helm_release`.

## Risks

- The `base-cronjob` chart changes live in a separate repository path and must be released before clients can consume the default chart version.
- RBAC is intentionally broad because Helm uninstall can delete many resource kinds created by releases.
- Cluster-specific CRDs or API groups may require additional `rbac.rules` overrides.
