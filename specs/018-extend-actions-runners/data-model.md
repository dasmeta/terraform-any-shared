# Data Model

## Runner scope

- `repositories`: optional deduplicated collection of `owner/repository`
  targets.
- `organization`: optional single organization identifier without `/`.
- Invariant: repository and organization targets cannot coexist.
- Fallback: when both are omitted, the historical `repo_name` is effective.

## Authentication source

- `personal_access_token`: historical sensitive token input.
- `github_auth_secret_name`: optional name of an externally managed Kubernetes
  Secret in the controller namespace.
- Invariant: exactly one source is non-empty.
- Secret contract: the referenced Secret contains the legacy chart's
  `github_token` key.

## Runner registration

- `name`: historical `runner_name` for legacy mode; normalized target-derived
  name plus short hash for new multi-target mode.
- `namespace`: configurable namespace shared with the controller release.
- `scope_kind`: `repository` or `organization`.
- `scope_target`: one repository or one organization.
- Relationship: every registration depends on the one controller release.

## Cluster credential source

- `kubectl_config_path`: historical local path or `null`.
- When non-null: the module configures kubectl from that path.
- When null: kubectl provider environment defaults supply the credentials.
- Helm credentials remain consumer/provider configuration and are not module
  inputs.

## Operator outputs

- `runner_resource_names`: sorted non-sensitive list of effective Kubernetes
  runner resource names.
- `runner_scope_mode`: `legacy_repository`, `repositories`, or `organization`.
- `runner_targets`: sorted non-sensitive list of effective targets.
