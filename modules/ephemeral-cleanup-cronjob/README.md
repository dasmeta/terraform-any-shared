# Ephemeral Helm Cleanup Terraform Module

This module installs the cleanup job through the DasMeta `base-cronjob` Helm chart.

It configures one CronJob that:

- mounts `scripts/ephemeral-helm-cleanup.sh` from a chart-managed ConfigMap
- runs on a configurable schedule
- selects namespaces by `namespace_name_pattern`
- uses a chart-managed ServiceAccount
- creates RBAC through `base-cronjob` `jobs[].rbac`

## Usage

```hcl
module "ephemeral_helm_cleanup" {
  source = "./modules/ephemeral-cleanup-cronjob"

  namespace              = "staging"
  schedule               = "0 2 * * *"
  namespace_name_pattern = "ephemeral"
}
```

## Use A Local Chart During Development

Use this while testing local changes to `/Users/juliaaghamyan/Desktop/dasmeta/helm/charts/base-cronjob`:

```hcl
module "ephemeral_helm_cleanup" {
  source = "./modules/ephemeral-cleanup-cronjob"

  chart_repository = null
  chart_name       = "/Users/juliaaghamyan/Desktop/dasmeta/helm/charts/base-cronjob"
  chart_version    = null

  namespace              = "staging"
  schedule               = "0 2 * * *"
  namespace_name_pattern = "ephemeral"
}
```

## Example With Overrides

```hcl
module "ephemeral_helm_cleanup" {
  source = "./modules/ephemeral-cleanup-cronjob"

  release_name           = "ephemeral-helm-cleanup"
  job_name               = "ephemeral-helm-cleanup"
  namespace              = "ops"
  schedule               = "30 1 * * *"
  namespace_name_pattern = "preview"

  image = {
    repository = "alpine/k8s"
    tag        = "1.20.15"
  }

  resources = {
    requests = {
      cpu    = "50m"
      memory = "64Mi"
    }
    limits = {
      cpu    = "250m"
      memory = "256Mi"
    }
  }
}
```

## Important Behavior

The script matches namespaces by substring. For example, `namespace_name_pattern = "ephemeral"` matches `ephemeral`, `api-ephemeral-pr-123`, and `web-ephemeral-demo`.

The job uses cluster-wide RBAC by default because Helm release cleanup may delete many namespaced Kubernetes resource types across every matched namespace. Override `rbac.rules` only when the target cluster has a narrower, tested permission model.

## Inputs

| Name | Description | Default |
| --- | --- | --- |
| `release_name` | Helm release name. | `ephemeral-helm-cleanup` |
| `chart_repository` | Helm repository containing `base-cronjob`; set `null` for local chart path. | `https://dasmeta.github.io/helm` |
| `chart_name` | Chart name or local chart path. | `base-cronjob` |
| `chart_version` | `base-cronjob` chart version; set `null` for local chart path. | `0.1.39` |
| `namespace` | Namespace where Helm installs the release. | `staging` |
| `create_namespace` | Whether Helm creates the namespace. | `false` |
| `job_name` | CronJob name. | `ephemeral-helm-cleanup` |
| `schedule` | Cron schedule for the cleanup job. | `0 2 * * *` |
| `namespace_name_pattern` | Substring used to select namespaces. | `ephemeral` |
| `image` | Image registry, repository, tag, and pull policy. | `alpine/k8s:1.20.15` |
| `dry_run` | Log uninstall commands without executing them. | `false` |
| `suspend` | Suspend future CronJob executions. | `false` |
| `concurrency_policy` | CronJob concurrency policy. | `Forbid` |
| `successful_jobs_history_limit` | Number of successful finished jobs to retain. | `1` |
| `failed_jobs_history_limit` | Number of failed finished jobs to retain. | `1` |
| `starting_deadline_seconds` | Optional deadline in seconds for missed jobs. | `null` |
| `job_backoff_limit` | Number of retries before marking the job failed. | `1` |
| `ttl_seconds_after_finished` | Optional TTL in seconds for finished jobs. | `null` |
| `restart_policy` | Pod restart policy. | `OnFailure` |
| `service_account` | ServiceAccount settings passed to `base-cronjob`. | create enabled |
| `rbac` | RBAC settings passed to `base-cronjob`; empty rules use cleanup defaults. | cluster-wide enabled |
| `resources` | Optional container CPU and memory requests and limits. | `null` |
| `node_selector` | Optional node selector for the cleanup pod. | `{}` |
| `tolerations` | Optional tolerations for the cleanup pod. | `[]` |
| `labels` | Labels passed to `base-cronjob`. | `[]` |
| `pod_annotations` | Pod annotations passed to `base-cronjob`. | `{}` |
| `extra_job_values` | Additional values merged into the generated job object. | `{}` |
| `extra_values` | Additional values merged into the Helm values root. | `{}` |
| `wait` | Whether Terraform waits for Helm release resources. | `true` |
| `atomic` | Whether Helm rolls back failed installs or upgrades. | `true` |
| `timeout` | Helm operation timeout in seconds. | `300` |

## Outputs

| Name | Description |
| --- | --- |
| `release_name` | Helm release name. |
| `release_namespace` | Namespace where the release is installed. |
| `release_status` | Helm release status. |
| `job_name` | CronJob name configured through `base-cronjob`. |
| `helm_values` | Rendered values passed to the Helm chart. |
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.13 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | ~> 2.13 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.this](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_atomic"></a> [atomic](#input\_atomic) | Whether Helm should roll back failed installs or upgrades. | `bool` | `true` | no |
| <a name="input_chart_name"></a> [chart\_name](#input\_chart\_name) | Helm chart name, or a local path to the base-cronjob chart. | `string` | `"base-cronjob"` | no |
| <a name="input_chart_repository"></a> [chart\_repository](#input\_chart\_repository) | Helm repository containing the base-cronjob chart. Set to null when chart\_name is a local chart path. | `string` | `"https://dasmeta.github.io/helm"` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | base-cronjob chart version. Set to null when using a local chart path. | `string` | `"0.1.39"` | no |
| <a name="input_concurrency_policy"></a> [concurrency\_policy](#input\_concurrency\_policy) | CronJob concurrency policy. | `string` | `"Forbid"` | no |
| <a name="input_create_namespace"></a> [create\_namespace](#input\_create\_namespace) | Whether Helm should create the target namespace. | `bool` | `false` | no |
| <a name="input_dry_run"></a> [dry\_run](#input\_dry\_run) | When true, the script logs helm uninstall commands without executing them. | `bool` | `false` | no |
| <a name="input_extra_job_values"></a> [extra\_job\_values](#input\_extra\_job\_values) | Additional values merged into the generated base-cronjob job object. | `any` | `{}` | no |
| <a name="input_extra_values"></a> [extra\_values](#input\_extra\_values) | Additional values merged into the Helm values root. | `any` | `{}` | no |
| <a name="input_failed_jobs_history_limit"></a> [failed\_jobs\_history\_limit](#input\_failed\_jobs\_history\_limit) | Number of failed finished jobs to retain. | `number` | `1` | no |
| <a name="input_image"></a> [image](#input\_image) | Container image settings for the cleanup job. The image must include kubectl and helm. | <pre>object({<br/>    registry    = optional(string, "")<br/>    repository  = optional(string, "alpine/k8s")<br/>    tag         = optional(string, "1.20.15")<br/>    pull_policy = optional(string, "IfNotPresent")<br/>  })</pre> | `{}` | no |
| <a name="input_job_backoff_limit"></a> [job\_backoff\_limit](#input\_job\_backoff\_limit) | Number of retries before marking the job failed. | `number` | `1` | no |
| <a name="input_job_name"></a> [job\_name](#input\_job\_name) | CronJob name passed to base-cronjob. | `string` | `"ephemeral-helm-cleanup"` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Labels passed to base-cronjob. The chart expects label entries with name and value fields. | <pre>list(object({<br/>    name  = string<br/>    value = string<br/>  }))</pre> | `[]` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace where the Helm release is installed. | `string` | `"default"` | no |
| <a name="input_namespace_name_pattern"></a> [namespace\_name\_pattern](#input\_namespace\_name\_pattern) | Substring used by the cleanup script to select namespaces containing Helm releases to uninstall. | `string` | `"ephemeral"` | no |
| <a name="input_node_selector"></a> [node\_selector](#input\_node\_selector) | Optional node selector for the cleanup pod. | `map(string)` | `{}` | no |
| <a name="input_pod_annotations"></a> [pod\_annotations](#input\_pod\_annotations) | Pod annotations passed to base-cronjob. | `map(string)` | `{}` | no |
| <a name="input_rbac"></a> [rbac](#input\_rbac) | RBAC settings passed to base-cronjob. Empty rules use the cleanup defaults. | <pre>object({<br/>    create       = optional(bool, true)<br/>    cluster_wide = optional(bool, true)<br/>    name         = optional(string, "ephemeral-helm-cleanup-role")<br/>    rules = optional(list(object({<br/>      apiGroups = list(string)<br/>      resources = list(string)<br/>      verbs     = list(string)<br/>    })), [])<br/>  })</pre> | `{}` | no |
| <a name="input_release_name"></a> [release\_name](#input\_release\_name) | Helm release name. | `string` | `"ephemeral-helm-cleanup"` | no |
| <a name="input_resources"></a> [resources](#input\_resources) | Optional CPU and memory requests and limits for the cleanup container. | <pre>object({<br/>    requests = object({<br/>      cpu    = string<br/>      memory = string<br/>    })<br/>    limits = object({<br/>      cpu    = string<br/>      memory = string<br/>    })<br/>  })</pre> | `null` | no |
| <a name="input_restart_policy"></a> [restart\_policy](#input\_restart\_policy) | Pod restart policy for the cleanup job. | `string` | `"OnFailure"` | no |
| <a name="input_schedule"></a> [schedule](#input\_schedule) | Cron schedule for the cleanup job. | `string` | `"0 2 * * *"` | no |
| <a name="input_service_account"></a> [service\_account](#input\_service\_account) | ServiceAccount settings passed to base-cronjob. | <pre>object({<br/>    create      = optional(bool, true)<br/>    name        = optional(string, "ephemeral-helm-cleanup")<br/>    labels      = optional(map(string), {})<br/>    annotations = optional(map(string), {})<br/>  })</pre> | `{}` | no |
| <a name="input_starting_deadline_seconds"></a> [starting\_deadline\_seconds](#input\_starting\_deadline\_seconds) | Optional deadline in seconds for starting a missed job. | `number` | `null` | no |
| <a name="input_successful_jobs_history_limit"></a> [successful\_jobs\_history\_limit](#input\_successful\_jobs\_history\_limit) | Number of successful finished jobs to retain. | `number` | `1` | no |
| <a name="input_suspend"></a> [suspend](#input\_suspend) | Whether to suspend future CronJob executions. | `bool` | `false` | no |
| <a name="input_timeout"></a> [timeout](#input\_timeout) | Helm operation timeout in seconds. | `number` | `300` | no |
| <a name="input_tolerations"></a> [tolerations](#input\_tolerations) | Optional tolerations for the cleanup pod. | <pre>list(object({<br/>    key                = optional(string)<br/>    operator           = optional(string)<br/>    value              = optional(string)<br/>    effect             = optional(string)<br/>    toleration_seconds = optional(number)<br/>  }))</pre> | `[]` | no |
| <a name="input_ttl_seconds_after_finished"></a> [ttl\_seconds\_after\_finished](#input\_ttl\_seconds\_after\_finished) | Optional TTL in seconds for finished jobs. | `number` | `null` | no |
| <a name="input_wait"></a> [wait](#input\_wait) | Whether Terraform waits for Helm release resources. | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_helm_values"></a> [helm\_values](#output\_helm\_values) | Rendered values passed to the base-cronjob Helm chart. |
| <a name="output_job_name"></a> [job\_name](#output\_job\_name) | CronJob name configured through base-cronjob. |
| <a name="output_release_name"></a> [release\_name](#output\_release\_name) | Helm release name. |
| <a name="output_release_namespace"></a> [release\_namespace](#output\_release\_namespace) | Namespace where the Helm release is installed. |
| <a name="output_release_status"></a> [release\_status](#output\_release\_status) | Helm release status. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
