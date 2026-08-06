# Authentik Terraform Module

Deploys the official Authentik Helm chart using an external PostgreSQL database
and a pre-existing Kubernetes configuration Secret. It is the shared identity
component for platform deployments.

## Scope

This module owns one Authentik Helm release only. It does not create a
namespace, database instance, database, database user, grants, Kubernetes
Secret, ingress, DNS record, Authentik provider, application, user, group, or
flow. Those concerns remain with their dedicated modules or Authentik-native
configuration.

The chart's bundled PostgreSQL is always disabled. Current Authentik releases
do not require Redis, so this module does not provision or configure Redis.

## Prerequisites

Before applying the module:

1. Create the namespace, normally with the shared `k8s/namespace` module.
2. Create an external PostgreSQL database, user, and grants through the
   standard database module.
3. Have the approved secret-management mechanism create a Secret in the target
   namespace. It must contain these keys:

   - `AUTHENTIK_SECRET_KEY`
   - `AUTHENTIK_POSTGRESQL__PASSWORD`

Terraform receives only the Secret name. It never creates, reads, accepts, or
outputs the values.

## Usage

```hcl
module "authentik" {
  source = "dasmeta/shared/any//modules/authentik"

  namespace                 = "example-platform"
  configuration_secret_name = "authentik-configuration"

  database = {
    host = "postgresql.example.internal"
    name = "authentik"
    user = "authentik"
  }
}
```

Use `server_service_name` and `server_service_http_port` as the backend of a
separately managed ingress. The module deliberately has no hostname or ingress
input.

### Additional chart settings

Use `extra_helm_config` for any supported official-chart setting that is not a
first-class module input, for example workload sizing:

```hcl
extra_helm_config = {
  server = {
    replicas = 2
  }
}
```

These values are rendered before the module's required values. They can extend
the chart, but cannot override the external database, configuration Secret,
release fullname, bundled-PostgreSQL disablement, or ClusterIP HTTP service
contract. Ingress, tenant/application configuration, and secret contents stay
outside this module.

## Operations

Chart upgrades are explicit through `chart_version`. Review Authentik release
notes and its database migration requirements before changing it. Helm uses an
atomic install/upgrade, cleans up failed new installs, waits for readiness, and
uses a 15-minute timeout.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 3.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_helm"></a> [helm](#provider\_helm) | 3.2.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [helm_release.this](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Reviewed version of the official Authentik Helm chart. | `string` | `"2026.5.6"` | no |
| <a name="input_configuration_secret_name"></a> [configuration\_secret\_name](#input\_configuration\_secret\_name) | Existing Secret name containing AUTHENTIK\_SECRET\_KEY and AUTHENTIK\_POSTGRESQL\_\_PASSWORD. | `string` | n/a | yes |
| <a name="input_database"></a> [database](#input\_database) | Non-secret connection metadata for the externally provisioned Authentik PostgreSQL database. | <pre>object({<br/>    host = string                 # External PostgreSQL hostname or service name.<br/>    name = string                 # Existing PostgreSQL database name.<br/>    user = string                 # Existing PostgreSQL username.<br/>    port = optional(number, 5432) # External PostgreSQL TCP port (integer from 1 through 65535).<br/>  })</pre> | n/a | yes |
| <a name="input_extra_helm_config"></a> [extra\_helm\_config](#input\_extra\_helm\_config) | Additional official Authentik chart values. Required module-owned database, Secret, release identity, and ClusterIP service values take precedence. | `any` | `{}` | no |
| <a name="input_name"></a> [name](#input\_name) | Helm release name and stable Authentik resource prefix. | `string` | `"authentik"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Existing Kubernetes namespace where Authentik is deployed. | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_release_chart_version"></a> [release\_chart\_version](#output\_release\_chart\_version) | Chart version used by the Authentik Helm release. |
| <a name="output_release_name"></a> [release\_name](#output\_release\_name) | Name of the Authentik Helm release. |
| <a name="output_release_namespace"></a> [release\_namespace](#output\_release\_namespace) | Namespace of the Authentik Helm release. |
| <a name="output_release_status"></a> [release\_status](#output\_release\_status) | Helm-reported Authentik release status. |
| <a name="output_server_service_http_port"></a> [server\_service\_http\_port](#output\_server\_service\_http\_port) | Internal Authentik server Service HTTP port for separately managed ingress. |
| <a name="output_server_service_name"></a> [server\_service\_name](#output\_server\_service\_name) | Internal Authentik server Service name for separately managed ingress. |
<!-- END_TF_DOCS -->
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 3.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_helm"></a> [helm](#provider\_helm) | ~> 3.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [helm_release.this](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Reviewed version of the official Authentik Helm chart. | `string` | `"2026.5.6"` | no |
| <a name="input_configuration_secret_name"></a> [configuration\_secret\_name](#input\_configuration\_secret\_name) | Existing Secret name containing AUTHENTIK\_SECRET\_KEY and AUTHENTIK\_POSTGRESQL\_\_PASSWORD. | `string` | n/a | yes |
| <a name="input_database"></a> [database](#input\_database) | Non-secret connection metadata for the externally provisioned Authentik PostgreSQL database. | <pre>object({<br/>    host = string                 # External PostgreSQL hostname or service name.<br/>    name = string                 # Existing PostgreSQL database name.<br/>    user = string                 # Existing PostgreSQL username.<br/>    port = optional(number, 5432) # External PostgreSQL TCP port (integer from 1 through 65535).<br/>  })</pre> | n/a | yes |
| <a name="input_extra_helm_config"></a> [extra\_helm\_config](#input\_extra\_helm\_config) | Additional official Authentik chart values. Required module-owned database, Secret, release identity, and ClusterIP service values take precedence. | `any` | `{}` | no |
| <a name="input_name"></a> [name](#input\_name) | Helm release name and stable Authentik resource prefix. | `string` | `"authentik"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Existing Kubernetes namespace where Authentik is deployed. | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_release_chart_version"></a> [release\_chart\_version](#output\_release\_chart\_version) | Chart version used by the Authentik Helm release. |
| <a name="output_release_name"></a> [release\_name](#output\_release\_name) | Name of the Authentik Helm release. |
| <a name="output_release_namespace"></a> [release\_namespace](#output\_release\_namespace) | Namespace of the Authentik Helm release. |
| <a name="output_release_status"></a> [release\_status](#output\_release\_status) | Helm-reported Authentik release status. |
| <a name="output_server_service_http_port"></a> [server\_service\_http\_port](#output\_server\_service\_http\_port) | Internal Authentik server Service HTTP port for separately managed ingress. |
| <a name="output_server_service_name"></a> [server\_service\_name](#output\_server\_service\_name) | Internal Authentik server Service name for separately managed ingress. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
