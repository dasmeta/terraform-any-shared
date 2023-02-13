# SETUP gitlab-runner in k8s

## TODO
In my case, service account was created with the name `gitlab-runner-gitlab-runner` and pipeline failed because was looking for a service account `gitlab-runner` and couldn't find.
Also, docker certificate configs were not available to the runner by passing via variables so I added this part to the configmap.


# My Use Case
```
module "gitlab_runner" {
  source  = "dasmeta/shared/any//modules/gitlab-runner"

  release_name              = "gitlab-runner-test"
  runner_name               = "gitlab-runner-test"
  namespace                 = "gitlab
  runner_registration_token = "***************"
  runner_tags               = "k8s"
  build_job_privileged      = true
  service_account           = "gitlab-runner-test-gitlab-runner"
  docker_cert = {
    enabled = true
  }
}
```

# Minimal Example

```
module "action-runner" {
  source                        = "dasmeta/shared/any//modules/"
  version                       = "0.1.0"

  namespace                     = "gitlab-runner"
  runner_name = "gitlab-runner"
  runner_registration_token = "Gjsod******"
  runner_token = "******"
}
```

## Example 2

```
module "action-runner" {
  source                        = "dasmeta/shared/any//modules/"
  version                       = "0.1.0"

  namespace                     = "gitlab-runner"
  runner_name = "gitlab-runner"
  runner_image                  = "gitlab/gitlab-runner"
  chart_version = 0.40.1
  runner_registration_token = "Gjsod******"
  runner_tags = "1.0.0"
  runner_locked = true
  run_untagged_jobs = false
  release_name = "gitlab_runner"
  gitlab_url = "https://gitlab.com/"
  concurrent = 10
  replicas = 1
  additional_secrets = {}
  runner_token = "******"
  unregister_runners = true
}
```


## Maximal Example

```
module "action-runner" {
  source                        = "dasmeta/shared/any//modules/"
  version                       = "0.1.0"

  namespace                     = "gitlab-runner"
  runner_name = "gitlab-runner"
  runner_image                  = "gitlab/gitlab-runner"
  create_namespace              = true
  service_account               = gitlab_runner
  service_account_annotations   = {}
  service_account_clusterwide_access = false
  chart_version = 0.40.1
  runner_registration_token = "Gjsod******"
  runner_tags = "1.0.0"
  runner_locked = true
  run_untagged_jobs = false
  release_name = "gitlab_runner"
  atomic  = true
  build_job_default_container_image = ubuntu:20.04
  values_file = "values.yaml"
  values = "additional_values.yaml"
  gitlab_url = "https://gitlab.com/"
  concurrent = 10
  replicas = 1
  create_service_account = true
  local_cache_dir = "/tmp/gitlab/cache"
  build_job_mount_docker_socket = false
  build_job_privileged = false
  build_job_node_selectors {}
  build_job_node_tolerations = {}
  build_job_pod_labels = {}
  build_job_pod_annotations = {}
  image_pull_secrets = []
  manager_node_selectors = {}
  manager_node_tolerations = {}
  manager_pod_labels = {}
  manager_pod_annotations = {}
  additional_secrets = {}
  runner_token = "******"
  unregister_runners = true
}
```

## Provider configuration

```
terraform {
  required_version = ">= 0.12"
  required_providers {
    helm       = ">= 1.3"
    kubernetes = ">= 1.13"
  }
}

```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name                                                                         | Version |
| ---------------------------------------------------------------------------- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform)    | >= 0.12 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm)                   | >= 1.3  |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 1.13 |

## Providers

| Name                                                 | Version |
| ---------------------------------------------------- | ------- |
| <a name="provider_helm"></a> [helm](#provider\_helm) | >= 1.3  |

## Modules

No modules.

## Resources

| Name                                                                                                               | Type     |
| ------------------------------------------------------------------------------------------------------------------ | -------- |
| [helm_release.gitlab_runner](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |

## Inputs

| Name                                                                                                                                           | Description                                                                                                                                                                                                                    | Type                                                                                                                                         | Default                                                                                                | Required |
| ---------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------ | :------: |
| <a name="input_additional_secrets"></a> [additional\_secrets](#input\_additional\_secrets)                                                     | additional secrets to mount into the manager pods                                                                                                                                                                              | `list(map(string))`                                                                                                                          | `[]`                                                                                                   |    no    |
| <a name="input_atomic"></a> [atomic](#input\_atomic)                                                                                           | whether to deploy the entire module as a unit                                                                                                                                                                                  | `bool`                                                                                                                                       | `true`                                                                                                 |    no    |
| <a name="input_build_dir"></a> [build\_dir](#input\_build\_dir)                                                                                | Path on nodes for caching                                                                                                                                                                                                      | `string`                                                                                                                                     | `null`                                                                                                 |    no    |
| <a name="input_build_job_default_container_image"></a> [build\_job\_default\_container\_image](#input\_build\_job\_default\_container\_image)  | Default container image to use for builds when none is specified                                                                                                                                                               | `string`                                                                                                                                     | `"ubuntu:18.04"`                                                                                       |    no    |
| <a name="input_build_job_limits"></a> [build\_job\_limits](#input\_build\_job\_limits)                                                         | The CPU allocation given to and the requested for build containers                                                                                                                                                             | `map(any)`                                                                                                                                   | <pre>{<br>  "cpu": "2",<br>  "memory": "1Gi"<br>}</pre>                                                |    no    |
| <a name="input_build_job_mount_docker_socket"></a> [build\_job\_mount\_docker\_socket](#input\_build\_job\_mount\_docker\_socket)              | Path on nodes for caching                                                                                                                                                                                                      | `bool`                                                                                                                                       | `false`                                                                                                |    no    |
| <a name="input_build_job_node_selectors"></a> [build\_job\_node\_selectors](#input\_build\_job\_node\_selectors)                               | A map of node selectors to apply to the pods                                                                                                                                                                                   | `map`                                                                                                                                        | `{}`                                                                                                   |    no    |
| <a name="input_build_job_node_tolerations"></a> [build\_job\_node\_tolerations](#input\_build\_job\_node\_tolerations)                         | A map of node tolerations to apply to the pods as defined https://docs.gitlab.com/runner/executors/kubernetes.html#other-configtoml-settings                                                                                   | `map`                                                                                                                                        | `{}`                                                                                                   |    no    |
| <a name="input_build_job_pod_annotations"></a> [build\_job\_pod\_annotations](#input\_build\_job\_pod\_annotations)                            | A map of annotations to be added to each build pod created by the Runner. The value of these can include environment variables for expansion. Pod annotations can be overwritten in each build.                                | `map`                                                                                                                                        | `{}`                                                                                                   |    no    |
| <a name="input_build_job_pod_labels"></a> [build\_job\_pod\_labels](#input\_build\_job\_pod\_labels)                                           | A map of labels to be added to each build pod created by the runner. The value of these can include environment variables for expansion.                                                                                       | `map`                                                                                                                                        | `{}`                                                                                                   |    no    |
| <a name="input_build_job_privileged"></a> [build\_job\_privileged](#input\_build\_job\_privileged)                                             | Run all containers with the privileged flag enabled. This will allow the docker:dind image to run if you need to run Docker                                                                                                    | `bool`                                                                                                                                       | `false`                                                                                                |    no    |
| <a name="input_build_job_requests"></a> [build\_job\_requests](#input\_build\_job\_requests)                                                   | The CPU allocation given to and the requested for build containers                                                                                                                                                             | `map(any)`                                                                                                                                   | <pre>{<br>  "cpu": "1",<br>  "memory": "512Mi"<br>}</pre>                                              |    no    |
| <a name="input_build_job_run_container_as_user"></a> [build\_job\_run\_container\_as\_user](#input\_build\_job\_run\_container\_as\_user)      | SecurityContext: runAsUser for all running job pods                                                                                                                                                                            | `string`                                                                                                                                     | `null`                                                                                                 |    no    |
| <a name="input_build_job_secret_volumes"></a> [build\_job\_secret\_volumes](#input\_build\_job\_secret\_volumes)                               | Secret volume configuration instructs Kubernetes to use a secret that is defined in Kubernetes cluster and mount it inside of the containes as defined https://docs.gitlab.com/runner/executors/kubernetes.html#secret-volumes | <pre>object({<br>    name       = string<br>    mount_path = string<br>    read_only  = string<br>    items      = map(string)<br>  })</pre> | <pre>{<br>  "items": {},<br>  "mount_path": null,<br>  "name": null,<br>  "read_only": null<br>}</pre> |    no    |
| <a name="input_cache"></a> [cache](#input\_cache)                                                                                              | Describes the properties of the cache.                                                                                                                                                                                         | <pre>object({<br>    type   = string<br>    path   = string<br>    shared = bool<br><br>  })</pre>                                           | <pre>{<br>  "path": "",<br>  "shared": false,<br>  "type": "local"<br>}</pre>                          |    no    |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version)                                                                    | The version of the chart                                                                                                                                                                                                       | `string`                                                                                                                                     | `"0.40.1"`                                                                                             |    no    |
| <a name="input_concurrent"></a> [concurrent](#input\_concurrent)                                                                               | Configure the maximum number of concurrent jobs                                                                                                                                                                                | `number`                                                                                                                                     | `10`                                                                                                   |    no    |
| <a name="input_create_namespace"></a> [create\_namespace](#input\_create\_namespace)                                                           | (Optional) Create the namespace if it does not yet exist. Defaults to false.                                                                                                                                                   | `bool`                                                                                                                                       | `true`                                                                                                 |    no    |
| <a name="input_create_service_account"></a> [create\_service\_account](#input\_create\_service\_account)                                       | If true, the service account, it's role and rolebinding will be created, else, the service account is assumed to already be created                                                                                            | `bool`                                                                                                                                       | `true`                                                                                                 |    no    |
| <a name="input_docker_fs_group"></a> [docker\_fs\_group](#input\_docker\_fs\_group)                                                            | The fsGroup to use for docker. This is added to security context when mount\_docker\_socket is enabled                                                                                                                         | `number`                                                                                                                                     | `412`                                                                                                  |    no    |
| <a name="input_gitlab_url"></a> [gitlab\_url](#input\_gitlab\_url)                                                                             | The GitLab Server URL (with protocol) that want to register the runner against                                                                                                                                                 | `string`                                                                                                                                     | `"https://gitlab.com/"`                                                                                |    no    |
| <a name="input_image_pull_secrets"></a> [image\_pull\_secrets](#input\_image\_pull\_secrets)                                                   | A array of secrets that are used to authenticate Docker image pulling.                                                                                                                                                         | `list(string)`                                                                                                                               | `[]`                                                                                                   |    no    |
| <a name="input_local_cache_dir"></a> [local\_cache\_dir](#input\_local\_cache\_dir)                                                            | Path on nodes for caching                                                                                                                                                                                                      | `string`                                                                                                                                     | `"/tmp/gitlab/cache"`                                                                                  |    no    |
| <a name="input_manager_node_selectors"></a> [manager\_node\_selectors](#input\_manager\_node\_selectors)                                       | A map of node selectors to apply to the pods                                                                                                                                                                                   | `map`                                                                                                                                        | `{}`                                                                                                   |    no    |
| <a name="input_manager_node_tolerations"></a> [manager\_node\_tolerations](#input\_manager\_node\_tolerations)                                 | A map of node tolerations to apply to the pods as defined https://docs.gitlab.com/runner/executors/kubernetes.html#other-configtoml-settings                                                                                   | `map`                                                                                                                                        | `{}`                                                                                                   |    no    |
| <a name="input_manager_pod_annotations"></a> [manager\_pod\_annotations](#input\_manager\_pod\_annotations)                                    | A map of annotations to be added to each build pod created by the Runner. The value of these can include environment variables for expansion. Pod annotations can be overwritten in each build.                                | `map`                                                                                                                                        | `{}`                                                                                                   |    no    |
| <a name="input_manager_pod_labels"></a> [manager\_pod\_labels](#input\_manager\_pod\_labels)                                                   | A map of labels to be added to each build pod created by the runner. The value of these can include environment variables for expansion.                                                                                       | `map`                                                                                                                                        | `{}`                                                                                                   |    no    |
| <a name="input_namespace"></a> [namespace](#input\_namespace)                                                                                  | n/a                                                                                                                                                                                                                            | `string`                                                                                                                                     | `"gitlab-runner"`                                                                                      |    no    |
| <a name="input_release_name"></a> [release\_name](#input\_release\_name)                                                                       | The helm release name                                                                                                                                                                                                          | `string`                                                                                                                                     | `"gitlab-runner"`                                                                                      |    no    |
| <a name="input_replicas"></a> [replicas](#input\_replicas)                                                                                     | the number of manager pods to create                                                                                                                                                                                           | `number`                                                                                                                                     | `1`                                                                                                    |    no    |
| <a name="input_run_untagged_jobs"></a> [run\_untagged\_jobs](#input\_run\_untagged\_jobs)                                                      | Specify if jobs without tags should be run. https://docs.gitlab.com/ce/ci/runners/#runner-is-allowed-to-run-untagged-jobs                                                                                                      | `bool`                                                                                                                                       | `false`                                                                                                |    no    |
| <a name="input_runner_image"></a> [runner\_image](#input\_runner\_image)                                                                       | The docker gitlab runner version. https://hub.docker.com/r/gitlab/gitlab-runner/tags/                                                                                                                                          | `string`                                                                                                                                     | `null`                                                                                                 |    no    |
| <a name="input_runner_locked"></a> [runner\_locked](#input\_runner\_locked)                                                                    | Specify whether the runner should be locked to a specific project/group                                                                                                                                                        | `string`                                                                                                                                     | `true`                                                                                                 |    no    |
| <a name="input_runner_name"></a> [runner\_name](#input\_runner\_name)                                                                          | name of the runner                                                                                                                                                                                                             | `string`                                                                                                                                     | n/a                                                                                                    |   yes    |
| <a name="input_runner_registration_token"></a> [runner\_registration\_token](#input\_runner\_registration\_token)                              | runner registration token                                                                                                                                                                                                      | `string`                                                                                                                                     | n/a                                                                                                    |   yes    |
| <a name="input_runner_tags"></a> [runner\_tags](#input\_runner\_tags)                                                                          | Specify the tags associated with the runner. Comma-separated list of tags.                                                                                                                                                     | `string`                                                                                                                                     | n/a                                                                                                    |   yes    |
| <a name="input_runner_token"></a> [runner\_token](#input\_runner\_token)                                                                       | token of already registered runer. to use this var.runner\_registration\_token must be set to null                                                                                                                             | `string`                                                                                                                                     | `null`                                                                                                 |    no    |
| <a name="input_service_account"></a> [service\_account](#input\_service\_account)                                                              | The name of the Service account to create                                                                                                                                                                                      | `string`                                                                                                                                     | `"gitlab-runner"`                                                                                      |    no    |
| <a name="input_service_account_annotations"></a> [service\_account\_annotations](#input\_service\_account\_annotations)                        | The annotations to add to the service account                                                                                                                                                                                  | `map`                                                                                                                                        | `{}`                                                                                                   |    no    |
| <a name="input_service_account_clusterwide_access"></a> [service\_account\_clusterwide\_access](#input\_service\_account\_clusterwide\_access) | Run the gitlab-bastion container with the ability to deploy/manage containers of jobs cluster-wide or only within namespace                                                                                                    | `bool`                                                                                                                                       | `false`                                                                                                |    no    |
| <a name="input_unregister_runners"></a> [unregister\_runners](#input\_unregister\_runners)                                                     | whether runners should be unregistered when pool is deprovisioned                                                                                                                                                              | `bool`                                                                                                                                       | `true`                                                                                                 |    no    |
| <a name="input_values"></a> [values](#input\_values)                                                                                           | Additional values to be passed to the gitlab-runner helm chart                                                                                                                                                                 | `map`                                                                                                                                        | `{}`                                                                                                   |    no    |
| <a name="input_values_file"></a> [values\_file](#input\_values\_file)                                                                          | Path to Values file to be passed to gitlab-runner helm chart                                                                                                                                                                   | `string`                                                                                                                                     | `null`                                                                                                 |    no    |

## Outputs

| Name                                                                          | Description                                 |
| ----------------------------------------------------------------------------- | ------------------------------------------- |
| <a name="output_chart_version"></a> [chart\_version](#output\_chart\_version) | The chart version                           |
| <a name="output_namespace"></a> [namespace](#output\_namespace)               | The namespace gitlab-runner was deployed in |
| <a name="output_release_name"></a> [release\_name](#output\_release\_name)    | The helm release name                       |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
