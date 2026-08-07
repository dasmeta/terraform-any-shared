# Quickstart: ExternalSecret full sync mode

1. Install External Secrets Operator v1 and create a SecretStore or ClusterSecretStore outside this module.
2. Decide the sync mode:
   - Default (recommended): list the properties the workload needs in `mappings` and leave `sync_all` unset.
   - Full sync: set `sync_all = true`, omit `mappings`, and accept that every property under `remote_key` lands in the target Secret with the provider's own key names.
3. Do not set both. A non-empty `mappings` together with `sync_all = true`, or an empty `mappings` with `sync_all = false`, fails during `terraform plan`.
4. Apply and wait for the ExternalSecret `Ready` condition before deploying the consumer.
5. Verify the target Secret name, type, and key names only; never print Secret data.

Existing consumers need no change: `sync_all` defaults to `false` and the rendered manifest is unchanged.
