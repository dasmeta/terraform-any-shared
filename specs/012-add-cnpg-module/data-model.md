# Data model: Shared CloudNativePG cluster module

| Entity | Attributes | Rules |
| --- | --- | --- |
| Cluster identity | `name`, `namespace`, labels, annotations | DNS-1123 name; one Cluster per module invocation. |
| Database bootstrap | database name, owner, existing Secret name | Secret is in the same namespace and has `username`/`password`; Terraform never accesses its values. |
| Storage | instance count, class, capacity | all are explicit; count and capacity must be positive. |
| Recovery | destination path, optional endpoint, existing S3 credentials Secret, retention, schedule | rendered only when configured; no credential values or bucket ownership. |
| Connection output | read/write service hostname, port, database, owner | deterministic and non-secret. |
