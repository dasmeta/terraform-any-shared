# CloudNativePG Terraform Module

Creates one CloudNativePG `Cluster` for a single application database and,
when configured, one daily `ScheduledBackup`. It is a generic Kubernetes
database component: Authentik, analytics, and other workloads consume it
through its non-secret connection outputs.

## Scope

This module owns the `postgresql.cnpg.io/v1` Cluster resource, including its
initial database/owner contract and optional Barman object-store recovery
configuration. It does not install or upgrade the CNPG operator; create a
namespace; create, read, or accept credentials; create an object-store bucket;
execute restores; manage backup retention outside the CNPG resource; create
additional databases/roles/grants; or configure applications.

## Prerequisites

Before applying the module:

1. Install CloudNativePG and verify the `postgresql.cnpg.io/v1` Cluster and
   ScheduledBackup CRDs are served by the target cluster.
2. Create the target namespace separately.
3. Materialize a `kubernetes.io/basic-auth` Secret in that namespace through
   the approved secret-management path. Its `username` must match
   `database.owner`, and it must contain a `password` key. Give the module only
   its name.
4. Select an explicit instance count, StorageClass, and storage capacity.
   `hcloud-volumes` is the current Hetzner/Rancher default but is not assumed
   by this module.
5. If backup is enabled, separately create the destination bucket and a
   same-namespace Secret containing the referenced S3 credential keys. Define
   and regularly test restore procedures outside this module.

The module pins a PostgreSQL image that is compatible with the currently
installed CNPG baseline. Review CNPG and PostgreSQL upgrade guidance before
overriding `image_name`.

## Usage

```hcl
module "application_postgres" {
  source = "dasmeta/shared/any//modules/cnpg"

  name      = "application-postgres"
  namespace = "application"
  instances = 3

  storage = {
    class = "hcloud-volumes"
    size  = "20Gi"
  }

  database = {
    name                  = "application"
    owner                 = "application_owner"
    bootstrap_secret_name = "application-postgres-owner"
  }

  backup = {
    destination_path        = "s3://database-backups/application-postgres"
    credentials_secret_name = "application-postgres-backup"
    endpoint_url            = "https://object.example.internal"
  }
}
```

Use `rw_service_hostname`, `port`, `database_name`, and `database_owner` in a
separately managed application configuration. Synchronize the matching
password through the existing Secret-management system; do not route it
through Terraform.

## Operations

`kubectl_manifest` creates the CNPG resources but does not wait for the CNPG
Cluster `Ready` condition. Before deploying a dependent workload, wait for it:

```sh
kubectl wait --for=condition=Ready \
  clusters.postgresql.cnpg.io/application-postgres \
  --namespace application --timeout=15m
```

When `backup` is set, the module archives WAL to the configured Barman
object-store destination and creates a daily six-field CNPG schedule
(`0 0 0 * * *`). The backup source and credentials remain external. Establish
retention review, restore drills, monitoring, and alerting in the owning
platform operations process.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | ~> 1.14 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_kubectl"></a> [kubectl](#provider\_kubectl) | 1.19.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [kubectl_manifest.cluster](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.scheduled_backup](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_annotations"></a> [annotations](#input\_annotations) | Additional annotations applied to the Cluster resource. | `map(string)` | `{}` | no |
| <a name="input_backup"></a> [backup](#input\_backup) | Optional S3-compatible Barman recovery configuration. credentials\_secret\_name is an existing same-namespace Secret; Terraform only renders key references. schedule uses CNPG's six-field cron format including seconds. | <pre>object({<br/>    destination_path        = string<br/>    credentials_secret_name = string<br/>    access_key_id_key       = optional(string, "access-key-id")<br/>    secret_access_key_key   = optional(string, "secret-access-key")<br/>    endpoint_url            = optional(string)<br/>    region_key              = optional(string)<br/>    session_token_key       = optional(string)<br/>    retention_policy        = optional(string, "30d")<br/>    schedule                = optional(string, "0 0 0 * * *")<br/>    immediate               = optional(bool, true)<br/>  })</pre> | `null` | no |
| <a name="input_database"></a> [database](#input\_database) | Initial application database and owner. bootstrap\_secret\_name is an existing same-namespace kubernetes.io/basic-auth Secret with username and password keys; its values are never read by Terraform. | <pre>object({<br/>    name                  = string<br/>    owner                 = string<br/>    bootstrap_secret_name = string<br/>  })</pre> | n/a | yes |
| <a name="input_enable_pod_monitor"></a> [enable\_pod\_monitor](#input\_enable\_pod\_monitor) | Whether CNPG should create a PodMonitor. Set false when the Prometheus Operator CRDs are unavailable. | `bool` | `true` | no |
| <a name="input_image_name"></a> [image\_name](#input\_image\_name) | Pinned CloudNativePG PostgreSQL image. Override only after reviewing the operator and PostgreSQL upgrade path. | `string` | `"ghcr.io/cloudnative-pg/postgresql:16.13@sha256:425e365273a0519c9cc1deb199a69c226734041a9a59a1f8250fecb06f6dcbb5"` | no |
| <a name="input_instances"></a> [instances](#input\_instances) | Desired number of CloudNativePG instances. Set explicitly to match the workload availability target. | `number` | n/a | yes |
| <a name="input_labels"></a> [labels](#input\_labels) | Additional labels applied to the Cluster resource. | `map(string)` | `{}` | no |
| <a name="input_name"></a> [name](#input\_name) | CloudNativePG Cluster name. It also determines the read/write Service and optional ScheduledBackup name. | `string` | n/a | yes |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Existing Kubernetes namespace where the CNPG Cluster and credential Secrets reside. | `string` | n/a | yes |
| <a name="input_pod_anti_affinity_type"></a> [pod\_anti\_affinity\_type](#input\_pod\_anti\_affinity\_type) | CNPG hostname pod anti-affinity policy. required provides high availability where nodes allow it; preferred relaxes scheduling pressure. | `string` | `"required"` | no |
| <a name="input_postgresql_parameters"></a> [postgresql\_parameters](#input\_postgresql\_parameters) | Additional PostgreSQL parameters merged with the enforced SCRAM password encryption setting. | `map(string)` | `{}` | no |
| <a name="input_resources"></a> [resources](#input\_resources) | Optional CPU and memory requests and limits for each PostgreSQL instance. | <pre>object({<br/>    limits   = optional(map(string), {})<br/>    requests = optional(map(string), {})<br/>  })</pre> | `{}` | no |
| <a name="input_storage"></a> [storage](#input\_storage) | StorageClass and requested persistent-volume capacity for each CNPG instance. | <pre>object({<br/>    class = string<br/>    size  = string<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | CloudNativePG Cluster name. |
| <a name="output_database_name"></a> [database\_name](#output\_database\_name) | Initial application database name. |
| <a name="output_database_owner"></a> [database\_owner](#output\_database\_owner) | Initial application database owner role. |
| <a name="output_namespace"></a> [namespace](#output\_namespace) | Namespace containing the Cluster and its generated Services. |
| <a name="output_port"></a> [port](#output\_port) | PostgreSQL port exposed by the CNPG read/write Service. |
| <a name="output_rw_service_hostname"></a> [rw\_service\_hostname](#output\_rw\_service\_hostname) | Cluster-local CNPG read/write Service hostname for application traffic. |
| <a name="output_rw_service_name"></a> [rw\_service\_name](#output\_rw\_service\_name) | CNPG read/write Service name for application traffic. |
| <a name="output_scheduled_backup_name"></a> [scheduled\_backup\_name](#output\_scheduled\_backup\_name) | ScheduledBackup resource name, or null when backup is not configured. |
<!-- END_TF_DOCS -->
