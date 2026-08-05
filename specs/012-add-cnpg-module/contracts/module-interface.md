# CNPG module interface contract

## Required inputs

- `name`: Cluster DNS label.
- `namespace`: existing target namespace.
- `instances`: desired CNPG instance count.
- `storage`: storage class and capacity.
- `database`: initial database name, owner name, and existing bootstrap Secret
  name.

## Optional inputs

- labels and annotations.
- published PostgreSQL image override.
- Pod resource requests/limits.
- PostgreSQL parameter map, except the module-enforced SCRAM password setting.
- hostname anti-affinity policy.

## Outputs

- `cluster_name`, `namespace`, `database_name`, `database_owner`, and `port`.
- `rw_service_name` / `rw_service_hostname`.
- `ro_service_name` / `ro_service_hostname`.
- `r_service_name` / `r_service_hostname`.

No input or output contains credential values. Backup, ObjectStore, monitoring,
and restore interfaces are deliberately outside this module.
