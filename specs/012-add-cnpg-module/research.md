# Research: Shared CloudNativePG cluster module

## Module location

`dasmeta/terraform-any-shared/modules/cnpg` is the appropriate home: CNPG is
generic Kubernetes database infrastructure used by multiple workloads, rather
than an Authentik or analytics concern.

## Resource rendering

The repository already uses `gavinbunney/kubectl` for custom resources. Its
generic manifest does not require CRD OpenAPI schema discovery during planning,
unlike `kubernetes_manifest`. The CloudNativePG Cluster CR remains the narrow
provider-independent baseline.

The upstream `cloudnative-pg/charts` cluster chart was considered but not
selected. It adds Helm release/version coupling and a broad chart values
surface; the module's purpose is one typed Cluster contract, not a second
operator/chart lifecycle abstraction.

## Current capabilities

- Use Cluster `initdb`, managed owner role, storage, anti-affinity, and
  `inheritedMetadata`: supported Cluster API capabilities.
- Use a published multi-architecture PostgreSQL 16.13 image manifest digest:
  `16.13-system-bookworm@sha256:98df8a04201d957af5975be2a2d52f357b8cfdc11f554a76be0321b0660ebfb6`.
- Native `backup.barmanObjectStore`, retention, ScheduledBackup, and
  `monitoring.enablePodMonitor` are not exposed. CNPG 1.26 deprecates these
  paths for new deployments and directs Barman users to the plugin/ObjectStore
  approach. That plugin is a separate cluster/platform concern.

## Compatibility boundary

CNPG 1.20 is EOL. This module supports CNPG 1.26 or later and does not present
older releases as a supported baseline. Cluster operators upgrade their own
operator before production adoption; the operator lifecycle is intentionally
outside this module's privilege boundary.

## Readiness

`kubectl_manifest.wait` is retained for repository convention and deletion
finalization behavior. It does not wait for the CNPG Cluster Ready condition;
dependent workloads must use `kubectl wait --for=condition=Ready`.
