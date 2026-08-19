# Data Model: Shared ExternalSecret module

- **Secret store reference**: Existing store `name` and optional `kind`.
- **Target Secret**: `name`, typed Kubernetes Secret `type`, `creation_policy`, and `deletion_policy`.
- **Mapping**: `secret_key` written to the target paired with a `remote_property` read from the single `remote_key`.

One module instance renders one ExternalSecret, which references one store, one remote key, one target Secret, and one or more mappings.
