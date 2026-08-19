# Data Model: SFTPGo Terraform Module

## SFTPGo Deployment Configuration

- `name`: Helm release name.
- `namespace`: Kubernetes namespace for the release.
- `create_namespace`: Whether Helm creates the namespace.
- `chart_repository`: SFTPGo chart repository.
- `chart`: Chart name.
- `chart_version`: Chart version.
- `atomic`, `wait`, `cleanup_on_fail`, `timeout`: Helm lifecycle behavior.
- `strategy`: Deployment strategy passed to chart values.
- `image_pull_secrets`: Optional image pull secrets passed to chart values.
- `extra_values`: Advanced chart values merged last.

Validation:

- `name` and `namespace` must be non-empty.
- `extra_values` is documented as an escape hatch, not the primary interface.

## S3 Storage Configuration

- `bucket`: S3 bucket name.
- `region`: S3 region.
- `access_key`: S3 access key ID.
- `access_secret`: Sensitive S3 access secret.
- `endpoint`: Optional S3-compatible endpoint.
- `force_path_style`: Optional path-style setting for S3-compatible providers.

Validation:

- `bucket`, `region`, `access_key`, and `access_secret` must be non-empty.
- `access_secret` is a sensitive Terraform input.

## Admin Bootstrap Configuration

- `enabled`: Whether chart default admin creation is enabled.
- `username`: Default admin username.
- `password`: Sensitive default admin password.

Validation:

- Password must be non-empty when admin bootstrap is enabled.

## Bootstrap User Configuration

- `username`: SFTPGo username.
- `password`: Sensitive user password.
- `key_prefix`: Optional S3 key prefix; defaults to `<username>/`.
- `home_dir`: Optional SFTPGo home directory; defaults to `/var/lib/sftpgo/<username>`.
- `require_password_change`: Whether the user must change password.

Validation:

- At least one bootstrap user is expected for the reusable S3-backed deployment path.
- Usernames and passwords must be non-empty.

## Persistence Configuration

- `enabled`: Whether chart persistence is enabled.
- `storage_class_name`: Optional storage class.
- `access_modes`: PVC access modes.
- `storage`: Requested storage size.

Validation:

- Storage request must be non-empty when persistence is enabled.

## Ingress Configuration

- `enabled`: Whether UI ingress is enabled.
- `class_name`: Ingress class.
- `annotations`: Ingress annotations.
- `hosts`: Host/path rules.
- `tls`: Optional TLS blocks.

Validation:

- Host entries must use neutral examples in repository examples and tests.

## Resources Configuration

- `requests`: CPU and memory requests.
- `limits`: CPU and memory limits.

Validation:

- Defaults should be suitable for a small common deployment and overrideable by consumers.
