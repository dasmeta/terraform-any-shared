# Data Model: Keycloak Helm Wrapper Module

## Entity: Keycloak Module Input Contract

**Purpose**: Represents the curated Terraform interface exposed by
`modules/keycloak` for the supported first-version deployment path.

**Fields**:
- `name`: Helm release name
- `namespace`: Kubernetes namespace for the release
- `create_namespace`: whether the namespace is created by Helm
- `chart_version`: pinned upstream chart version chosen for the maintained
  module baseline
- `hostname`: primary Keycloak hostname
- `replica_count`: desired number of Keycloak replicas when the chart supports
  it in the curated path
- `resources`: CPU and memory requests/limits for the main workload
- `ingress`: structured ingress/application exposure settings used for a
  consumer-managed ingress path
- `bootstrap_credentials`: structured selection of existing-secret references
  or raw values for supported admin/bootstrap credentials
- `external_database`: structured connection settings for the required
  consumer-managed external database
- `extra_labels` or equivalent limited metadata fields: optional common-case
  metadata supported by the wrapper

**Relationships**:
- One `Keycloak Module Input Contract` configures one `Keycloak Deployment
  Baseline`
- One `Keycloak Module Input Contract` includes one `Bootstrap Credential
  Policy`
- One `Keycloak Module Input Contract` includes one `External Database Config`
- One `Keycloak Module Input Contract` may include one `Ingress Config`

## Entity: Bootstrap Credential Policy

**Purpose**: Defines how the module sources and validates Keycloak bootstrap or
admin credentials.

**Fields**:
- `existing_secret_name`: name of a consumer-managed Kubernetes Secret when the
  preferred reference path is used
- `existing_secret_keys`: mapping of expected secret keys for the credential
  fields the chart needs
- `raw_values`: raw admin/bootstrap values supplied directly to Terraform when
  the fallback path is used
- `managed_secret_name`: name for the module-managed Secret created from raw
  values when that fallback path is selected
- `selection_mode`: `existing-secret` or `raw-values`
- `conflict_rule`: validation error when both modes are configured for the same
  credential scope

**Relationships**:
- One `Bootstrap Credential Policy` belongs to one `Keycloak Module Input
  Contract`
- One `Bootstrap Credential Policy` may produce one module-managed Kubernetes
  Secret
- One `Bootstrap Credential Policy` informs one `Module Output Contract`

## Entity: External Database Config

**Purpose**: Represents the required database connection details that remain
consumer-managed but must be wired into the Keycloak release.

**Fields**:
- `host`
- `port`
- `database_name`
- `username`
- `credential_source`: existing secret reference or raw password value,
  depending on the final curated interface
- `ssl_mode` or equivalent minimal connection toggle if the chosen chart path
  requires it

**Relationships**:
- One `External Database Config` belongs to one `Keycloak Module Input
  Contract`
- One `External Database Config` is referenced by one `Keycloak Deployment
  Baseline`

## Entity: Ingress Config

**Purpose**: Captures the limited ingress-related settings that the module will
support without taking ownership of ingress infrastructure.

**Fields**:
- `enabled`
- `class_name`
- `annotations`
- `hostname`
- `tls_secret_name`
- `path_rules` if required by the selected chart path

**Relationships**:
- One `Ingress Config` belongs to one `Keycloak Module Input Contract`
- One `Ingress Config` influences one `Keycloak Deployment Baseline`
- One `Ingress Config` may be summarized in the `Module Output Contract`

## Entity: Keycloak Deployment Baseline

**Purpose**: Defines the supported default deployment shape the repository will
stand behind for the first maintained release.

**Fields**:
- `upstream_chart`: fixed to `codecentric/keycloakx`
- `deployment_mode`: `external-database`
- `secret_strategy`: selected bootstrap credential mode
- `ingress_boundary`: application configuration only; no ingress controller or
  certificate issuance ownership
- `unsupported_capabilities`: bundled database paths, broad values pass-through,
  and other approval-gated advanced chart internals

**Relationships**:
- One `Keycloak Deployment Baseline` is configured by one `Keycloak Module
  Input Contract`
- One `Keycloak Deployment Baseline` is documented by the README, example, and
  test artifacts

## Entity: Module Output Contract

**Purpose**: Describes the stable outputs returned to downstream consumers and
operators after deployment.

**Fields**:
- `release_name`
- `release_namespace`
- `release_status`
- `helm_metadata`
- `chart_version`
- `bootstrap_secret_name` when a stable Secret name is part of the supported
  contract
- `ingress_hostnames` when ingress is enabled

**Relationships**:
- One `Module Output Contract` is produced by one `Keycloak Deployment
  Baseline`
- One `Module Output Contract` is documented in README and validated by
  example/test assets

## State Transitions

### Bootstrap Credential Selection Lifecycle

- `unconfigured` -> `existing-secret`
  when a valid existing Secret reference is supplied
- `unconfigured` -> `raw-values`
  when raw bootstrap values are supplied and no conflicting existing Secret
  reference is set
- `existing-secret` -> `invalid`
  when raw values are also set for the same credential scope
- `raw-values` -> `invalid`
  when an existing Secret reference is also set for the same credential scope

### Module Delivery Lifecycle

- `planned` -> `implemented`
  when the Terraform module files and curated interface are added
- `implemented` -> `documented`
  when README, example, and test artifacts match the final interface
- `documented` -> `validated`
  when formatting, validation, and workflow inclusion checks pass
