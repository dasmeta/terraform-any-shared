# Qdrant Terraform Module


#### This Terraform module deploys Qdrant, an open-source vector database, into a Kubernetes cluster using the official Qdrant Helm chart.

#### The module is designed to:
   * Deploy Qdrant via Helm into a configurable Kubernetes namespace
   * Provide sensible defaults out of the box
   * Allow users to override Helm values through a single config variable
   * Integrate cleanly with existing Kubernetes and Helm providers (e.g. EKS, GKE, AKS)

Note: This module does not manage the Kubernetes cluster itself. A reachable cluster and properly configured providers are required.

#### What this module is for:
   * Running Qdrant as a managed Kubernetes workload
   * Storing and querying vector embeddings
   * Supporting search, recommendation, and AI/ML workloads


<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 3.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | ~> 3.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.qdrant](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_chart_name"></a> [chart\_name](#input\_chart\_name) | Name of the Helm chart to deploy from the repository. | `string` | `"qdrant"` | no |
| <a name="input_chart_repo"></a> [chart\_repo](#input\_chart\_repo) | Helm repository URL that hosts the Qdrant chart. | `string` | `"https://qdrant.github.io/qdrant-helm"` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Specific version of the Qdrant Helm chart to deploy. If empty, the latest available version is used. | `string` | `"1.16.3"` | no |
| <a name="input_config"></a> [config](#input\_config) | Map of Helm values that override the module's default chart configuration.<br/>The values provided here are shallow-merged on top of the defaults and are<br/>passed directly to the Qdrant Helm chart. | `any` | `{}` | no |
| <a name="input_create_namespace"></a> [create\_namespace](#input\_create\_namespace) | Whether to create the Kubernetes namespace if it does not already exist. | `bool` | `false` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the Helm release for Qdrant. | `string` | `"qdrant"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Kubernetes namespace where the Qdrant Helm release will be deployed. | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
