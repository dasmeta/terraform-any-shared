# Research: Shared CloudNativePG cluster module

## Decisions

### Use the shared Terraform module catalog

**Decision**: Add `modules/cnpg` to `dasmeta/terraform-any-shared`.

**Rationale**: CNPG is generic Kubernetes database infrastructure. It is
consumed by Authentik and data analytics, but neither application owns the
database abstraction.

**Alternatives considered**: An Authentik-specific module would duplicate the
same lifecycle for other workloads; raw manifests in the YAML consumer repo
would bypass the shared module catalog.

### Use the repository's Kubectl custom-resource convention

**Decision**: Use `gavinbunney/kubectl` and `kubectl_manifest`.

**Rationale**: Existing modules use this provider for CRDs. It can plan the
generic manifest without discovering the CNPG CRD OpenAPI schema.

**Alternatives considered**: `kubernetes_manifest` is provider-maintained but
requires CRD schema discovery during plan; no supported DasMeta CNPG module
exists.

### Support the common application-database contract

**Decision**: One Cluster, one initial database, one owner role, one existing
bootstrap Secret, explicit data storage, and optional S3-compatible recovery.

**Rationale**: This matches CNPG's initdb and managed-role API while keeping
credentials and application-level grants outside Terraform.

**Alternatives considered**: arbitrary SQL, multiple roles/databases, Secret
creation, or raw CR overrides would broaden the module beyond its safe common
case.

### Align with the installed operator baseline

**Decision**: Use `postgresql.cnpg.io/v1`, compatible with the installed
CloudNativePG 1.20.1 controller. Default image is the currently deployed,
digest-pinned PostgreSQL 16.13 image.

**Rationale**: The target Rancher cluster already has the CRD and controller,
and current production clusters use PostgreSQL 16.13 with hostname
anti-affinity, data checksums, monitoring, disabled superuser access, and
Hetzner persistent volumes.

**Alternatives considered**: Installing or upgrading the operator is a
cluster-wide concern and out of scope.
