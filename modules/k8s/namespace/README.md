# Kubernetes Namespace Terraform Module

Creates one Kubernetes namespace with caller-managed labels and annotations.
It is intended to be the shared deployment boundary for platform components.

## Scope

This module creates only a namespace. It does not create workloads, service
accounts, quotas, network policies, secrets, databases, ingress, or DNS.

## Usage

```hcl
module "namespace" {
  source = "dasmeta/shared/any//modules/k8s/namespace"

  name = "example-platform"

  labels = {
    "app.kubernetes.io/part-of" = "example-platform"
  }
}
```

The consuming root configures the Kubernetes provider. Dependent modules should
use `namespace_name`; no credential or cluster configuration is returned.

## Inputs

| Name | Description | Type | Default | Required |
| --- | --- | --- | --- | --- |
| `name` | Stable Kubernetes namespace name. | `string` | n/a | yes |
| `labels` | Caller-managed namespace labels. | `map(string)` | `{}` | no |
| `annotations` | Caller-managed namespace annotations. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| --- | --- |
| `namespace_name` | Managed namespace name. |
| `namespace_id` | Terraform provider namespace ID. |
| `namespace_uid` | Kubernetes-assigned immutable UID. |

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | ~> 2.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [kubernetes_namespace_v1.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace_v1) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_annotations"></a> [annotations](#input\_annotations) | Caller-managed annotations applied to the namespace. | `map(string)` | `{}` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Caller-managed labels applied to the namespace. | `map(string)` | `{}` | no |
| <a name="input_name"></a> [name](#input\_name) | Stable Kubernetes DNS-1123 namespace label. Changing it replaces the namespace. | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_namespace_id"></a> [namespace\_id](#output\_namespace\_id) | Terraform provider ID of the managed Kubernetes namespace. |
| <a name="output_namespace_name"></a> [namespace\_name](#output\_namespace\_name) | Name of the managed Kubernetes namespace. |
| <a name="output_namespace_uid"></a> [namespace\_uid](#output\_namespace\_uid) | Kubernetes-assigned immutable UID of the managed namespace. |
<!-- END_TF_DOCS -->
