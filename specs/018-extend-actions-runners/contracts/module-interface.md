# Module Interface Contract

## Preserved inputs

- `runner_name`: historical runner resource name and prefix for new target names.
- `repo_name`: historical single repository input name and resource path, now
  explicitly required when `runner_scope` is empty. The unsafe implicit target
  was removed with requester approval.
- `personal_access_token`: historical token authentication source; now sensitive
  and nullable so an existing Secret can be selected instead.
- `kubectl_config_path`: historical kubeconfig path; `null` selects provider
  environment credentials.

## New inputs

- `runner_scope`:
  - `repositories`: optional set of `owner/repository` identifiers.
  - `organization`: optional organization identifier.
- `github_auth_secret_name`: optional pre-existing Secret name, mutually
  exclusive with `personal_access_token`.
- `namespace`: optional controller and runner namespace; defaults to the
  historical namespace.
- `chart_version`: optional legacy chart version; omission preserves historical
  unpinned behavior.

## Validation

- Organization and repository collection cannot both be populated.
- Empty `runner_scope` requires a non-empty `repo_name`; no repository is
  selected implicitly.
- Repository identifiers follow `owner/repository`; organization contains no
  slash.
- Exactly one token or Secret authentication source is configured.
- New namespace and Secret-name values are valid non-empty Kubernetes names.
- Duplicate repositories collapse to one target.

## Rendered resources

- Exactly one legacy controller Helm release.
- Historical fallback: one repository Runner using the historical resource
  address and `runner_name`.
- Repository collection: one Runner per unique target with deterministic unique
  metadata names whose hash includes the full runner name, scope, and target.
- Organization: one Runner with the organization field.
- All runner manifests depend on controller installation.

## Outputs

- `runner_resource_names`: non-sensitive effective resource names.
- `runner_scope_mode`: selected target mode.
- `runner_targets`: non-sensitive selected targets.

The module never outputs authentication material or manages the external
Secret's contents.

## Legacy provider boundary

The internal kubectl provider remains for backward compatibility. Terraform
therefore rejects module-level `count`, `for_each`, and `depends_on`; a future
major release is required to migrate safely to caller-supplied providers.
Consumers must destroy module-managed resources before removing the module
block so the internal provider remains available for destruction.

Changing an existing deployment from `repo_name` to
`runner_scope.repositories` replaces the historical manifest address rather
than migrating it in place.
