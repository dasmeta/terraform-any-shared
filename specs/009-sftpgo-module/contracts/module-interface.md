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
