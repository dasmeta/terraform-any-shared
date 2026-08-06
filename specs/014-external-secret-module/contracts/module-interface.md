# Module Interface Contract

## Inputs

- Required: `name`, `namespace`, `secret_store`, `remote_key`, `target`, and non-empty `mappings`.
- Optional: `refresh_interval`, default `1h`.

`secret_store` contains the existing store name and optional kind. `target` contains the target Secret name, optional Secret type, and bounded lifecycle policies. Each mapping contains one Kubernetes `secret_key` and one provider `remote_property`.

## Rendered resource

One `external-secrets.io/v1` ExternalSecret with Periodic refresh, the selected store, target template type, and a `spec.data` entry for each mapping.

## Outputs

- `external_secret_name`
- `target_secret_name`
