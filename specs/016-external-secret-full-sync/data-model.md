# Data Model: ExternalSecret full sync mode

- **Sync mode** (new): `sync_all`, a boolean defaulting to `false`. `false` selects explicit list sync; `true` selects full sync.
- **Mapping** (changed): still `secret_key` plus `remote_property`, but the list now defaults to `[]`. Content rules (non-blank values, unique `secret_key`) remain in variable validation; the presence rule moved to the resource precondition.
- **Secret store reference**: unchanged.
- **Target Secret**: unchanged.

## Mode matrix

| `sync_all` | `mappings` | Result |
| --- | --- | --- |
| `false` (default) | non-empty | `spec.data[]`, one entry per mapping. No `spec.dataFrom`. |
| `false` | empty | Plan fails on the precondition. |
| `true` | empty | `spec.dataFrom[0].extract.key = remote_key`. No `spec.data`. |
| `true` | non-empty | Plan fails on the precondition. |

One module instance still renders one ExternalSecret referencing one store, one remote key, and one target Secret, in exactly one sync mode.
