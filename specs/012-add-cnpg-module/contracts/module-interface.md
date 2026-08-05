# CNPG module interface contract

## Required inputs

- `name`: Cluster DNS label.
- `namespace`: existing target namespace.
- `instances`: desired CNPG instance count.
- `storage`: storage class and capacity.
- `database`: initial database name, owner name, and existing bootstrap Secret
  name.

## Optional inputs

- metadata labels and annotations.
- PostgreSQL 16 image override.
- pod resource requests/limits.
- PostgreSQL parameter map.
- backup object-store configuration, its existing credentials Secret reference,
  retention, and six-field CNPG schedule.

## Outputs

- `cluster_name`, `namespace`, `database_name`, and `database_owner`.
- `rw_service_name`, `rw_service_hostname`, and `port`.
- `scheduled_backup_name`, or null if recovery is not configured.

No input or output contains credential values.
