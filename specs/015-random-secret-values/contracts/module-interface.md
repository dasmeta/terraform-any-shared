# Module Interface Contract

## Inputs

- `generated_values`: required map of named Random password policies.
- `static_values`: optional map of string metadata.
- `aliases`: optional map from a destination key to one generated or static
  source key.

Keys must be non-empty, unique across all three maps, and aliases must not
reference aliases.

## Outputs

- `values`: the complete credential payload, always `sensitive = true`.
- `keys`: the non-sensitive sorted result key list.

The module never creates a remote secret, Kubernetes Secret, database, or
application resource.
