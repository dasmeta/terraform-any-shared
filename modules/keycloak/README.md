# keycloak

This module deploys Keycloak through the `codecentric/keycloakx` Helm chart as
an opinionated Terraform wrapper for the common deployment path: Keycloak on an
existing Kubernetes cluster, backed by a consumer-managed external database,
with optional ingress wiring for a consumer-managed ingress controller.

The first version intentionally keeps the interface narrow:

- no generic Helm values pass-through
- no bundled in-module database path
- no ingress controller, DNS, or certificate lifecycle ownership

### Passwords: two supported modes (pick one per credential)

| Mode | When to use |
|------|-------------|
| **Raw in Terraform** (`admin_password`, `database.password`) | Same pattern as other Dasmeta modules that take `${workspace.outputs...}` (e.g. Grafana `grafana_admin_password`). Terraform creates Kubernetes Secrets and Helm references them. |
| **Existing Secret** (`admin_password_secret_name`, `database.password_secret_name`) | You manage Secrets in the cluster (e.g. **ExternalSecret** → AWS Secrets Manager). Terraform only references names; password material is not in this workspace’s inputs. |

You do **not** need a module change to use the Grafana-style approach: pass interpolated secrets as `admin_password` and `database.password`. Do **not** set the `*_secret_name` fields at the same time, and **do not** duplicate the same credential with ExternalSecret unless you intentionally want two sources of truth.

## Baseline usage

```terraform
module "keycloak" {
  source = "dasmeta/shared/any//modules/keycloak"

  hostname       = "keycloak.example.com"
  admin_password = "change-me-admin-password"

  database = {
    host     = "postgresql.example.internal"
    name     = "keycloak"
    username = "keycloak"
    password = "change-me-db-password"
  }
}
```

## Terraform Cloud / remote workspace outputs (Grafana-style)

Link the secrets workspace (e.g. `0-accounts/root/master-secret`) and pass outputs into the module. **Omit** `admin_password_secret_name` / `database.password_secret_name` in this mode.

```terraform
module "keycloak" {
  source = "dasmeta/shared/any//modules/keycloak"

  hostname = "sso.example.com"

  admin_password = data.tfe_outputs.master_secret.values.results.secrets.KEYCLOAK_ADMIN_PASSWORD

  database = {
    host     = "postgresql.example.internal"
    name     = "keycloak"
    username = "keycloak"
    password = data.tfe_outputs.master_secret.values.results.secrets.KEYCLOAK_DB_PASSWORD
  }
}
```

In generated DasMeta YAML this corresponds to `${0-accounts/root/master-secret.secrets.<KEY>}` on `admin_password` and `database.password` (exact structure depends on your wrapper).

## Customization with existing Kubernetes Secrets

Use this when Secrets are created **outside** this Terraform run (ExternalSecret, manual `kubectl`, etc.).

```terraform
module "keycloak" {
  source = "dasmeta/shared/any//modules/keycloak"

  hostname                   = "sso.example.com"
  admin_password_secret_name = "keycloak-admin-password"

  ingress = {
    enabled            = true
    ingress_class_name = "nginx"
    annotations = {
      "cert-manager.io/cluster-issuer" = "letsencrypt"
    }
    tls_secret_name = "keycloak-tls"
  }

  database = {
    host                 = "postgresql.example.internal"
    name                 = "keycloak"
    username             = "keycloak"
    password_secret_name = "keycloak-db-password"
  }
}
```

## Prerequisites

- an existing Kubernetes cluster reachable through the Helm and Kubernetes providers
- a consumer-managed external database supported by the upstream chart
- a consumer-managed ingress controller when ingress is enabled
- for **existing-Secret** mode: consumer-managed Kubernetes Secrets (or ExternalSecrets) in the target namespace
- for **raw password** mode: same linked workspaces as other apps (e.g. master-secret); secrets still end up in Terraform state as **sensitive** attributes

## Supported boundaries

- Password sourcing is explicit: **either** raw `admin_password` / `database.password` **or** `*_secret_name` for each credential, never both for the same slot.
- The module defaults Keycloak to `/` rather than the upstream `/auth` path to
  keep the consumer-facing URL simpler.
- Low-frequency upstream chart options remain out of scope until explicitly
  approved as a wrapper expansion.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | ~> 2.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | ~> 2.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.this](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_secret_v1.admin_password](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret_v1) | resource |
| [kubernetes_secret_v1.database_password](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret_v1) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin_password"></a> [admin\_password](#input\_admin\_password) | Raw admin password used only when the module manages the bootstrap secret. | `string` | `null` | no |
| <a name="input_admin_password_secret_key"></a> [admin\_password\_secret\_key](#input\_admin\_password\_secret\_key) | The key inside the admin password Secret. | `string` | `"password"` | no |
| <a name="input_admin_password_secret_name"></a> [admin\_password\_secret\_name](#input\_admin\_password\_secret\_name) | Existing Kubernetes Secret name that contains the Keycloak admin password. | `string` | `null` | no |
| <a name="input_admin_username"></a> [admin\_username](#input\_admin\_username) | The initial Keycloak admin username. | `string` | `"admin"` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | The version of the codecentric/keycloakx Helm chart to deploy. | `string` | `"7.1.9"` | no |
| <a name="input_create_namespace"></a> [create\_namespace](#input\_create\_namespace) | Create the namespace if it does not already exist. | `bool` | `true` | no |
| <a name="input_database"></a> [database](#input\_database) | The external database configuration for Keycloak. | <pre>object({<br/>    host                 = string<br/>    name                 = string<br/>    username             = string<br/>    vendor               = optional(string, "postgres")<br/>    port                 = optional(number, 5432)<br/>    password             = optional(string)<br/>    password_secret_name = optional(string)<br/>    password_secret_key  = optional(string, "password")<br/>  })</pre> | n/a | yes |
| <a name="input_hostname"></a> [hostname](#input\_hostname) | The public hostname configured for Keycloak. | `string` | n/a | yes |
| <a name="input_ingress"></a> [ingress](#input\_ingress) | Ingress configuration for the consumer-managed ingress path. | <pre>object({<br/>    enabled            = optional(bool, true)<br/>    ingress_class_name = optional(string)<br/>    annotations        = optional(map(string), {})<br/>    path               = optional(string, "/")<br/>    path_type          = optional(string, "Prefix")<br/>    tls_secret_name    = optional(string)<br/>  })</pre> | `{}` | no |
| <a name="input_name"></a> [name](#input\_name) | The name of the Helm release. | `string` | `"keycloak"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | The Kubernetes namespace where Keycloak is deployed. | `string` | `"keycloak"` | no |
| <a name="input_pod_labels"></a> [pod\_labels](#input\_pod\_labels) | Additional labels applied to the Keycloak pod. | `map(string)` | `{}` | no |
| <a name="input_replicas"></a> [replicas](#input\_replicas) | The number of Keycloak replicas to run. | `number` | `1` | no |
| <a name="input_resources"></a> [resources](#input\_resources) | CPU and memory resource requests and limits for Keycloak. | <pre>object({<br/>    limits   = optional(map(string), {})<br/>    requests = optional(map(string), {})<br/>  })</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_admin_password_secret_name"></a> [admin\_password\_secret\_name](#output\_admin\_password\_secret\_name) | The Kubernetes Secret name used for the admin password. |
| <a name="output_database_password_secret_name"></a> [database\_password\_secret\_name](#output\_database\_password\_secret\_name) | The Kubernetes Secret name used for the database password. |
| <a name="output_helm_metadata"></a> [helm\_metadata](#output\_helm\_metadata) | Helm release metadata for the deployed Keycloak release. |
| <a name="output_ingress_hostnames"></a> [ingress\_hostnames](#output\_ingress\_hostnames) | Ingress hostnames configured for Keycloak. |
| <a name="output_release_chart_version"></a> [release\_chart\_version](#output\_release\_chart\_version) | Chart version used for the Keycloak Helm release. |
| <a name="output_release_name"></a> [release\_name](#output\_release\_name) | Name of the Keycloak Helm release. |
| <a name="output_release_namespace"></a> [release\_namespace](#output\_release\_namespace) | Namespace of the Keycloak Helm release. |
| <a name="output_release_status"></a> [release\_status](#output\_release\_status) | Status of the Keycloak Helm release. |
<!-- END_TF_DOCS -->
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | ~> 2.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | ~> 2.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.this](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_namespace_v1.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace_v1) | resource |
| [kubernetes_secret_v1.admin_password](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret_v1) | resource |
| [kubernetes_secret_v1.database_password](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret_v1) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin_password"></a> [admin\_password](#input\_admin\_password) | Raw admin password used only when the module manages the bootstrap secret. | `string` | `null` | no |
| <a name="input_admin_password_secret_key"></a> [admin\_password\_secret\_key](#input\_admin\_password\_secret\_key) | The key inside the admin password Secret. | `string` | `"password"` | no |
| <a name="input_admin_password_secret_name"></a> [admin\_password\_secret\_name](#input\_admin\_password\_secret\_name) | Existing Kubernetes Secret name that contains the Keycloak admin password. | `string` | `null` | no |
| <a name="input_admin_username"></a> [admin\_username](#input\_admin\_username) | The initial Keycloak admin username. | `string` | `"admin"` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | The version of the codecentric/keycloakx Helm chart to deploy. | `string` | `"7.1.9"` | no |
| <a name="input_create_namespace"></a> [create\_namespace](#input\_create\_namespace) | When true, create the target namespace with the Kubernetes provider before secrets and Helm (required so bootstrap Secrets can be applied). | `bool` | `true` | no |
| <a name="input_database"></a> [database](#input\_database) | The external database configuration for Keycloak. | <pre>object({<br/>    host                 = string<br/>    name                 = string<br/>    username             = string<br/>    vendor               = optional(string, "postgres")<br/>    port                 = optional(number, 5432)<br/>    password             = optional(string)<br/>    password_secret_name = optional(string)<br/>    password_secret_key  = optional(string, "password")<br/>  })</pre> | n/a | yes |
| <a name="input_helm_timeout"></a> [helm\_timeout](#input\_helm\_timeout) | Seconds Helm waits for the release when wait is true. Keycloak startup often exceeds the provider default (300s), causing context deadline exceeded with atomic installs. | `number` | `900` | no |
| <a name="input_hostname"></a> [hostname](#input\_hostname) | The public hostname configured for Keycloak. | `string` | n/a | yes |
| <a name="input_hostname_strict"></a> [hostname\_strict](#input\_hostname\_strict) | When false, sets KC\_HOSTNAME\_STRICT=false so Keycloak accepts any Host header (e.g. kubectl port-forward to 127.0.0.1 without redirects to hostname). Set true when public URLs must strictly match hostname. | `bool` | `false` | no |
| <a name="input_ingress"></a> [ingress](#input\_ingress) | Ingress configuration for the consumer-managed ingress path. | <pre>object({<br/>    enabled            = optional(bool, true)<br/>    ingress_class_name = optional(string)<br/>    annotations        = optional(map(string), {})<br/>    path               = optional(string, "/")<br/>    path_type          = optional(string, "Prefix")<br/>    tls_secret_name    = optional(string)<br/>  })</pre> | `{}` | no |
| <a name="input_name"></a> [name](#input\_name) | The name of the Helm release. | `string` | `"keycloak"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | The Kubernetes namespace where Keycloak is deployed. | `string` | `"keycloak"` | no |
| <a name="input_pod_labels"></a> [pod\_labels](#input\_pod\_labels) | Additional labels applied to the Keycloak pod. | `map(string)` | `{}` | no |
| <a name="input_proxy_mode"></a> [proxy\_mode](#input\_proxy\_mode) | Sets keycloakx chart proxy.mode | `string` | `"xforwarded"` | no |
| <a name="input_replicas"></a> [replicas](#input\_replicas) | The number of Keycloak replicas to run. | `number` | `1` | no |
| <a name="input_resources"></a> [resources](#input\_resources) | CPU and memory resource requests and limits for Keycloak. | <pre>object({<br/>    limits   = optional(map(string), {})<br/>    requests = optional(map(string), {})<br/>  })</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_admin_password_secret_name"></a> [admin\_password\_secret\_name](#output\_admin\_password\_secret\_name) | The Kubernetes Secret name used for the admin password. |
| <a name="output_database_password_secret_name"></a> [database\_password\_secret\_name](#output\_database\_password\_secret\_name) | The Kubernetes Secret name used for the database password. |
| <a name="output_helm_metadata"></a> [helm\_metadata](#output\_helm\_metadata) | Helm release metadata for the deployed Keycloak release. |
| <a name="output_ingress_hostnames"></a> [ingress\_hostnames](#output\_ingress\_hostnames) | Ingress hostnames configured for Keycloak. |
| <a name="output_release_chart_version"></a> [release\_chart\_version](#output\_release\_chart\_version) | Chart version used for the Keycloak Helm release. |
| <a name="output_release_name"></a> [release\_name](#output\_release\_name) | Name of the Keycloak Helm release. |
| <a name="output_release_namespace"></a> [release\_namespace](#output\_release\_namespace) | Namespace of the Keycloak Helm release. |
| <a name="output_release_status"></a> [release\_status](#output\_release\_status) | Status of the Keycloak Helm release. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
