# Module Interface Contract: `modules/sftpgo`

## Required Inputs

- `s3_storage`: object with `bucket`, `region`, `access_key`, and sensitive `access_secret`.
- `admin.password`: sensitive admin password when admin bootstrap is enabled.
- `bootstrap_users`: list of user objects with `username` and sensitive `password`.

## Supported Optional Inputs

- Deployment: `name`, `namespace`, `create_namespace`, `chart_repository`, `chart`, `chart_version`, `atomic`, `wait`, `cleanup_on_fail`, `timeout`.
- S3 storage: `endpoint`, `force_path_style`.
- Admin bootstrap: `enabled`, `username`.
- Bootstrap users: `key_prefix`, `home_dir`, `require_password_change`.
- Chart values: `persistence`, `ingress`, `resources`, `strategy`, `image_pull_secrets`, `extra_values`.

## Outputs

- `helm_release_name`
- `helm_release_namespace`
- `helm_release_status`
- `helm_release_version`

## Compatibility Rules

- The module must not require provider configuration inside the module.
- Sensitive values are accepted through Terraform variables and may be stored in Terraform state as sensitive values.
- Examples and tests must use neutral placeholder names and never real customer hostnames, paths, or secrets.

## Trusted HTTP proxy (2026-09-30)

`web_proxy = null` preserves existing behavior. When supplied, requires `proxy_allowed: list(string)` containing nonempty valid CIDRs with nonzero prefix length. Optional `client_ip_proxy_header: string` defaults to `X-Forwarded-For`; optional `client_ip_header_depth: number` defaults to 0 and must be a nonnegative integer. Produces one HTTP binding on port 8080 with WebAdmin, WebClient and REST API enabled. Session configuration remains independently optional and retains its current defaults. `extra_values.config` retains its replacement semantics and must not be used to partially extend this generated configuration.

## SFTP external traffic policy (2026-09-30)

`sftp_service.external_traffic_policy` is optional, default `Cluster`, allowed `Cluster` or `Local`. Passed to LoadBalancer/NodePort Services. Omitted for ClusterIP; explicitly choosing Local with ClusterIP is rejected. No automatic AWS annotations or source allowlists are imposed by the module. Consumers choose the appropriate NLB routing/health-check annotations through the existing annotations map.

## Operational hardening follow-up (2026-09-30)

- web_session: optional signing_passphrase string or signing_passphrase_secret_ref={name,key}; exactly one required when web_session is provided. Reference resolves from an existing Secret in the release namespace through SFTPGO_HTTPD__SIGNING_PASSPHRASE. Module never reads or creates that Secret.
- bootstrap_users: default []; an empty list omits user-bootstrap without modifying existing SFTPGo accounts.
- shutdown: nullable object with grace_time=300 and termination_grace_period_seconds=330 defaults when enabled; positive integral grace time and strictly larger integral pod period required. Omission preserves old behavior.
- PDB, do-not-disrupt and node selection use existing extra_values. No unconditional eviction block is introduced.
