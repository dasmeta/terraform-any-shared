# GitHub Actions Runner

Deploy GitHub Actions self-hosted runners into Kubernetes. The default `legacy`
mode preserves the existing `actions.summerwind.dev/v1alpha1` controller and
Runner resources for current consumers. New deployments should select
`scale_set`, which installs GitHub's official Actions Runner Controller (ARC)
scale-set charts and uses GitHub's queue-driven autoscaling.

Legacy mode expects cert-manager to be available for its admission webhook. The
controller and Runner resources share `namespace`, which defaults to the
historical `actions-runner-system` namespace. Official scale-set mode does not
use legacy `Runner`, `RunnerDeployment`, or `HorizontalRunnerAutoscaler`
resources.

## Official GitHub ARC runner scale set

Set `deployment_mode = "scale_set"` for a new deployment. This installs these
GitHub-maintained OCI charts:

- `gha-runner-scale-set-controller`
- `gha-runner-scale-set`

The scale-set chart creates a listener that receives job demand from GitHub and
creates ephemeral runner pods. `min_runners` is the idle baseline and
`max_runners` is the capacity cap. The module enables the chart's supported
Docker-in-Docker mode for Docker build jobs.

```hcl
module "runner" {
  source  = "dasmeta/shared/any//modules/github-actions-runner"
  version = "<released-version>"

  deployment_mode             = "scale_set"
  namespace                   = "github-actions-runner"
  github_auth_secret_name     = "controller-manager"
  kubectl_config_path         = null

  scale_set = {
    github_config_url        = "https://github.com/example"
    runner_scale_set_name    = "example-runners"
    min_runners              = 1
    max_runners              = 3
    controller_chart_version = "0.14.2"
    chart_version            = "0.14.2"
  }
}
```

`github_config_url` can target one organization or one repository. An
organization URL serves repositories that GitHub allows the runner group to
access. Use separate module instances for separate repository-only scale sets.

Update a workflow to request the scale-set label rather than generic runner
labels:

```yaml
runs-on: example-runners
```

The pre-existing authentication Secret must be in `namespace`. For PAT
authentication it contains `github_token`; the official chart also supports a
Secret containing its documented GitHub App keys. The module references an
external Secret without reading or managing its value.

## Authentication

Choose exactly one authentication source:

- `github_auth_secret_name`: recommended for Terraform Cloud. The named Secret
  must already exist in `namespace` and contain a `github_token` key. The module
  references it without reading or storing the token.
- `personal_access_token`: backward-compatible mode in which the Helm chart
  creates the controller Secret. The input is sensitive, but its value remains
  part of Terraform state.

When Terraform Cloud supplies `KUBE_HOST`, `KUBE_TOKEN`, and the related
`KUBE_*` provider variables, set `kubectl_config_path = null`. Existing local
consumers can continue using the default `~/.kube/config` path. A null path also
disables local kubeconfig loading, preventing remote runs from falling back to
`localhost` when no file exists on the worker.

## Legacy provider limitation

For backward compatibility, this version retains the module's internal
`kubectl` provider configuration. Terraform therefore treats it as a legacy
module: callers cannot put the module block behind `count` or `for_each`, and
cannot add module-level `depends_on`. A caller-defined `kubectl` provider block
does not replace the module's internal configuration; use
`kubectl_config_path = null` to let that internal provider consume Terraform
Cloud `KUBE_*` environment credentials.

Use `runner_scope.repositories` when one module instance must serve several
repositories. Moving to caller-supplied providers requires a future major
module release because it changes how existing resources retain their provider
configuration in state. Destroy the module-managed resources before removing
the module block from a configuration; otherwise Terraform can report that the
module-owned provider configuration is no longer present.

## Organization runner with an existing Secret

```hcl
module "action_runner" {
  source  = "dasmeta/shared/any//modules/github-actions-runner"
  version = "<released-version>"

  namespace               = "github-actions-runner"
  runner_name             = "shared-runner"
  github_auth_secret_name = "controller-manager"
  kubectl_config_path     = null
  chart_version           = "0.23.7"

  runner_scope = {
    organization = "example"
  }
}
```

In YAML-managed infrastructure, map the same inputs into the module Setup and
attach the Terraform Cloud variable set that supplies the cluster credentials.
Keep the Secret value in the approved secret-management workflow, not in YAML.
Use a released module version before generating or planning the workspace.

## Multiple repository runners

```hcl
module "action_runner" {
  source  = "dasmeta/shared/any//modules/github-actions-runner"
  version = "<released-version>"

  namespace               = "github-actions-runner"
  github_auth_secret_name = "controller-manager"
  kubectl_config_path     = null
  chart_version           = "0.23.7"

  runner_scope = {
    repositories = [
      "example/api",
      "example/web",
    ]
  }
}
```

The module creates one deterministically named Runner resource per unique
repository. `repositories` and `organization` are mutually exclusive.

### Migrating an existing repository runner

Changing an existing deployment from `repo_name` to
`runner_scope.repositories` is a resource replacement, not a state-preserving
rename. Terraform destroys `kubectl_manifest.pv_mongo_main[0]` and creates a
keyed `kubectl_manifest.scoped_runner[...]`; GitHub consequently deregisters the
old Runner and registers a newly named one. Schedule that transition like a
runner replacement and review the plan before applying it.

## Backward-compatible single repository

Existing consumers can retain their current input shape and effective behavior:

```hcl
module "action_runner" {
  source  = "dasmeta/shared/any//modules/github-actions-runner"
  version = "<released-version>"

  runner_name           = "runner"
  repo_name             = "example/application"
  personal_access_token = var.github_runner_token
  kubectl_config_path   = "~/.kube/config"
}
```

Leaving `runner_scope` empty requires an explicit `repo_name` and preserves the
legacy Runner resource behavior. The module includes a Terraform state move for
the legacy Helm release when upgrading to the conditional implementation, so a
normal legacy upgrade does not replace the controller. There is no implicit
repository target.

## Local verification

From `modules/github-actions-runner`, initialize before running validation or
native tests:

```sh
terraform fmt -check -recursive .
terraform init -backend=false
terraform validate
terraform test
tflint --chdir=.
checkov -d .
tfsec .
terraform-docs markdown table --output-file README.md --output-mode inject .
```

The repository also emits Terraform validation/test, pre-commit, Checkov,
TFLint, and tfsec workflow signals for pull requests. Those existing signals
are currently informational rather than merge-blocking because their shared
workflow steps use `continue-on-error`; this module change does not alter
repository-wide automation or release ownership.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.0 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | ~> 1.14 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_helm"></a> [helm](#provider\_helm) | 2.17.0 |
| <a name="provider_kubectl"></a> [kubectl](#provider\_kubectl) | 1.19.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [helm_release.arc_scale_set](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.arc_scale_set_controller](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.legacy](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubectl_manifest.pv_mongo_main](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.scoped_runner](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Optional legacy actions-runner-controller Helm chart version. Null preserves the historical latest-compatible selection. | `string` | `null` | no |
| <a name="input_deployment_mode"></a> [deployment\_mode](#input\_deployment\_mode) | Runner deployment implementation. Use legacy to preserve the existing controller or scale\_set for the official GitHub ARC chart path. | `string` | `"legacy"` | no |
| <a name="input_github_auth_secret_name"></a> [github\_auth\_secret\_name](#input\_github\_auth\_secret\_name) | Name of an existing Secret in namespace containing the controller github\_token key. Mutually exclusive with personal\_access\_token. | `string` | `null` | no |
| <a name="input_kubectl_config_path"></a> [kubectl\_config\_path](#input\_kubectl\_config\_path) | Kubernetes config path. Set to null to let the kubectl provider use KUBE\_* environment credentials, as in Terraform Cloud. | `string` | `"~/.kube/config"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Kubernetes namespace in which the selected runner controller and runner resources are installed. | `string` | `"actions-runner-system"` | no |
| <a name="input_personal_access_token"></a> [personal\_access\_token](#input\_personal\_access\_token) | GitHub personal access token used by the selected controller path. Set to null when github\_auth\_secret\_name is provided. | `string` | `null` | no |
| <a name="input_repo_name"></a> [repo\_name](#input\_repo\_name) | GitHub repository in owner/name form for the legacy single-repository mode. Required when runner\_scope is empty. | `string` | `null` | no |
| <a name="input_runner_name"></a> [runner\_name](#input\_runner\_name) | Runner Name | `string` | `"runner"` | no |
| <a name="input_runner_scope"></a> [runner\_scope](#input\_runner\_scope) | Optional runner target selection. Set repositories or organization, but not both. An empty object preserves repo\_name behavior. | <pre>object({<br/>    repositories = optional(set(string), []) # Explicit GitHub repositories in owner/name form.<br/>    organization = optional(string)          # GitHub organization name for organization-wide runners.<br/>  })</pre> | `{}` | no |
| <a name="input_scale_set"></a> [scale\_set](#input\_scale\_set) | Official GitHub ARC runner scale-set configuration. Required only when deployment\_mode is scale\_set. | <pre>object({<br/>    github_config_url        = optional(string, null)                      # GitHub organization or repository HTTPS URL served by this scale set.<br/>    runner_scale_set_name    = optional(string, "github-runner-scale-set") # Workflow runs-on label and official runner scale-set name.<br/>    min_runners              = optional(number, 1)                         # Minimum idle ephemeral runners retained for new jobs.<br/>    max_runners              = optional(number, 3)                         # Maximum total ephemeral runners that GitHub may request.<br/>    controller_chart_version = optional(string, "0.14.2")                  # Official gha-runner-scale-set-controller chart version.<br/>    chart_version            = optional(string, "0.14.2")                  # Official gha-runner-scale-set chart version.<br/>  })</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_deployment_mode"></a> [deployment\_mode](#output\_deployment\_mode) | Selected runner deployment implementation: legacy or scale\_set. |
| <a name="output_runner_resource_names"></a> [runner\_resource\_names](#output\_runner\_resource\_names) | Kubernetes Runner resource names created by this module. |
| <a name="output_runner_scale_set_name"></a> [runner\_scale\_set\_name](#output\_runner\_scale\_set\_name) | Official runner scale-set workflow label when deployment\_mode is scale\_set; otherwise null. |
| <a name="output_runner_scope_mode"></a> [runner\_scope\_mode](#output\_runner\_scope\_mode) | Effective runner target mode: legacy\_repository, repositories, organization, or scale\_set. |
| <a name="output_runner_targets"></a> [runner\_targets](#output\_runner\_targets) | Effective repository or organization targets. |
<!-- END_TF_DOCS -->
