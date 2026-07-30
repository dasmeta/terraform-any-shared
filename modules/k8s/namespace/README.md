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
