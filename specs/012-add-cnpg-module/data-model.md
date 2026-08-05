# Data model: Shared CloudNativePG cluster module

| Entity | Attributes | Rules |
| --- | --- | --- |
| Cluster identity | `name`, `namespace`, labels, annotations | DNS-1123 labels; one Cluster per module invocation. |
| Bootstrap identity | database name, owner, existing basic-auth Secret name | Database/owner are valid PostgreSQL identifiers of at most 63 bytes; Secret values never enter Terraform. |
| Storage | instance count, class, capacity | Explicit, positive, whole-byte quantity; no milli-byte suffix. |
| Runtime metadata | labels and annotations | Applied to Cluster metadata and `spec.inheritedMetadata`. |
| Connection output | read/write, read-only, replica hostnames, port, database, owner | Deterministic and non-secret. |
