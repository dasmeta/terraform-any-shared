# Research: ExternalSecret full sync mode

## Decisions

- **Mechanism**: Use `spec.dataFrom[].extract` with the single configured `remote_key`. It is the documented ESO v1 way to pull every property of one remote secret into the target Secret.
- **Opt-in**: Gate it behind an explicit `sync_all` boolean, default `false`. Mode selection stays visible in the caller's code instead of being inferred from an empty `mappings` list.
- **Exclusivity**: Render exactly one of `spec.data` / `spec.dataFrom`. Mixing them is legal in ESO but makes the effective key set of the target Secret non-obvious.
- **Enforcement**: Use `lifecycle.precondition` on the `kubectl_manifest` resource. The rule spans `sync_all` and `mappings`, so variable validation cannot express it; the precondition still fails during plan.
- **Excluded**: `dataFrom[].find` stays out of scope. It matches remote secrets by regex or tag and would break the module's one-remote-key boundary.
- **Unchanged**: Store reference, target template type, refresh policy, and lifecycle policies behave identically in both modes.

## Relationship to 014

014 recorded "do not expose broad `dataFrom` extraction" while the module only served enumerable property sets. That decision is narrowed rather than reversed wholesale: extraction is now permitted against the one configured remote key, behind an opt-in, while cross-secret `find` remains excluded.

## Trade-off accepted

Full sync copies whatever property names the provider owns, so the module cannot rename keys and the target key set can change without a Terraform run. That is the point of the mode for consumers whose remote secret is managed elsewhere, and it is why explicit `mappings` remains the documented default.

Sources: [ESO ExternalSecret API](https://external-secrets.io/latest/api/externalsecret/) and [ESO API specification](https://external-secrets.io/latest/api/spec/).
