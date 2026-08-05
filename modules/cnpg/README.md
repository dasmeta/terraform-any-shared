# CloudNativePG Terraform Module

Creates one CloudNativePG `Cluster` with one initial application database and
owner. It is a cluster-only database component: application modules use its
non-secret service outputs, while operator, secret, backup, monitoring, and
application concerns stay with their dedicated owners.

## Scope

The module owns the `postgresql.cnpg.io/v1` Cluster resource, initial database
and owner contract, storage, availability defaults, inherited metadata, and
the deterministic CNPG `-rw`, `-ro`, and `-r` Service identities.

It does not install or upgrade CNPG; create a namespace; create, read, or
accept credentials; create a PodMonitor; configure backup plugins, ObjectStore,
buckets, schedules, or restores; manage additional databases/roles/grants; or
configure workloads.

## Prerequisites

1. Use CNPG 1.26 or later serving the `postgresql.cnpg.io/v1` Cluster API.
   CNPG 1.20 is EOL and is not a supported baseline for this module.
2. Create the namespace separately.
3. Materialize an existing `kubernetes.io/basic-auth` Secret in that namespace
   through the approved secret-management path. Its `username` must equal
   `database.owner` and it must contain a `password` key. Terraform receives
   only the Secret name.
4. Select explicit instances, StorageClass, and capacity. The module rejects
   milli-byte storage units such as `400m`.

The module's managed role supports the default CNPG application-owner role
attributes. Workloads requiring superuser, `CREATEDB`, `CREATEROLE`, or custom
grant behavior require a separate, explicitly scoped database-lifecycle
component.

## Usage

```hcl
module "application_postgres" {
  source = "dasmeta/shared/any//modules/cnpg"

  name      = "application-postgres"
  namespace = "application"
  instances = 3

  storage = {
    class = "standard-volumes"
    size  = "20Gi"
  }

  database = {
    name                  = "application"
    owner                 = "application_owner"
    bootstrap_secret_name = "application-postgres-owner"
  }
}
```

Use `rw_service_hostname` for writes, `ro_service_hostname` for replica-only
reads, or `r_service_hostname` for reads that can use any ready instance.
Configure the matching application password through the approved secret
manager; do not pass it through Terraform.

## Operations

`kubectl_manifest.wait` does not wait for CNPG Cluster readiness. Before
deploying a dependent workload, wait for the Cluster condition explicitly:

```sh
kubectl wait --for=condition=Ready \
  clusters.postgresql.cnpg.io/application-postgres \
  --namespace application --timeout=15m
```

The native CNPG Barman Cloud and PodMonitor interfaces are intentionally not
exposed: modern CNPG releases deprecate those paths. Add a plugin-based backup
or monitoring integration as a separately reviewed platform component.

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

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_annotations"></a> [annotations](#input\_annotations) | Additional annotations applied to the Cluster resource. | `map(string)` | `{}` | no |
| <a name="input_database"></a> [database](#input\_database) | Initial application database and owner. bootstrap\_secret\_name is an existing same-namespace kubernetes.io/basic-auth Secret with username and password keys; its values are never read by Terraform. | <pre>object({<br/>    name                  = string # Initial PostgreSQL database name.<br/>    owner                 = string # Initial PostgreSQL owner role name.<br/>    bootstrap_secret_name = string # Existing same-namespace basic-auth Secret name.<br/>  })</pre> | n/a | yes |
| <a name="input_image_name"></a> [image\_name](#input\_image\_name) | Pinned CloudNativePG PostgreSQL image. Override only after reviewing the operator and PostgreSQL upgrade path. | `string` | `"ghcr.io/cloudnative-pg/postgresql:16.13-system-bookworm@sha256:98df8a04201d957af5975be2a2d52f357b8cfdc11f554a76be0321b0660ebfb6"` | no |
| <a name="input_instances"></a> [instances](#input\_instances) | Desired number of CloudNativePG instances. Set explicitly to match the workload availability target. | `number` | n/a | yes |
| <a name="input_labels"></a> [labels](#input\_labels) | Additional labels applied to the Cluster resource. | `map(string)` | `{}` | no |
| <a name="input_name"></a> [name](#input\_name) | CloudNativePG Cluster name. It determines the generated read/write and read-only Service names. | `string` | n/a | yes |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Existing Kubernetes namespace where the CNPG Cluster and credential Secrets reside. | `string` | n/a | yes |
| <a name="input_pod_anti_affinity_type"></a> [pod\_anti\_affinity\_type](#input\_pod\_anti\_affinity\_type) | CNPG hostname pod anti-affinity policy. required provides high availability where nodes allow it; preferred relaxes scheduling pressure. | `string` | `"required"` | no |
| <a name="input_postgresql_parameters"></a> [postgresql\_parameters](#input\_postgresql\_parameters) | Additional PostgreSQL parameters merged with the enforced SCRAM password encryption setting. | `map(string)` | `{}` | no |
| <a name="input_resources"></a> [resources](#input\_resources) | Optional CPU and memory requests and limits for each PostgreSQL instance. | <pre>object({<br/>    limits   = optional(map(string), {}) # Optional resource limits for each PostgreSQL instance.<br/>    requests = optional(map(string), {}) # Optional resource requests for each PostgreSQL instance.<br/>  })</pre> | `{}` | no |
| <a name="input_storage"></a> [storage](#input\_storage) | StorageClass and requested persistent-volume capacity for each CNPG instance. | <pre>object({<br/>    class = string # StorageClass used for each PostgreSQL instance volume.<br/>    size  = string # Positive whole-byte Kubernetes storage quantity, such as 10Gi.<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | CloudNativePG Cluster name. |
| <a name="output_database_name"></a> [database\_name](#output\_database\_name) | Initial application database name. |
| <a name="output_database_owner"></a> [database\_owner](#output\_database\_owner) | Initial application database owner role. |
| <a name="output_namespace"></a> [namespace](#output\_namespace) | Namespace containing the Cluster and its generated Services. |
| <a name="output_port"></a> [port](#output\_port) | PostgreSQL port exposed by the CNPG read/write Service. |
| <a name="output_r_service_hostname"></a> [r\_service\_hostname](#output\_r\_service\_hostname) | Cluster-local CNPG read Service hostname that can route to any ready instance. |
| <a name="output_r_service_name"></a> [r\_service\_name](#output\_r\_service\_name) | CNPG read Service name that can route to any ready instance. |
| <a name="output_ro_service_hostname"></a> [ro\_service\_hostname](#output\_ro\_service\_hostname) | Cluster-local CNPG read-only Service hostname for replicas only. |
| <a name="output_ro_service_name"></a> [ro\_service\_name](#output\_ro\_service\_name) | CNPG read-only Service name for replicas only. |
| <a name="output_rw_service_hostname"></a> [rw\_service\_hostname](#output\_rw\_service\_hostname) | Cluster-local CNPG read/write Service hostname for application traffic. |
| <a name="output_rw_service_name"></a> [rw\_service\_name](#output\_rw\_service\_name) | CNPG read/write Service name for application traffic. |
<!-- END_TF_DOCS -->
