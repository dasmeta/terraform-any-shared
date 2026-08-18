# Module Interface Contract

## Inputs

- Required: `name`, `namespace`, `secret_store`, `remote_key`, `target`.
- Optional: `refresh_interval` (default `1h`), `labels`, `annotations`, `sync_all` (default `false`), `mappings` (default `[]`).

`sync_all = false` requires a non-empty `mappings`. `sync_all = true` requires an empty `mappings`. Either violation fails at plan time on the resource precondition with a message naming both valid modes.

## Rendered resource

One `external-secrets.io/v1` ExternalSecret with Periodic refresh, the selected store, and the target template type, plus exactly one of:

- `spec.data[]` — one entry per mapping, each with `secretKey` and `remoteRef.{key,property}` (list sync).
- `spec.dataFrom[0].extract.key` — the configured `remote_key` (full sync).

The block not selected is absent from the manifest.

## Outputs

- `external_secret_name`
- `target_secret_name`

Unchanged, and non-sensitive in both modes.

## Compatibility

Additive. Callers that set `mappings` and do not set `sync_all` produce a byte-identical manifest to the pre-016 module.
