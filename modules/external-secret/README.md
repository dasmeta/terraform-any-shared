# ExternalSecret Terraform Module

Creates one `external-secrets.io/v1` ExternalSecret that maps selected
properties from one provider-side secret into one typed Kubernetes Secret.

## Scope

The module owns only the ExternalSecret resource, its explicit property
mappings, and target Secret type/lifecycle policy. It never receives, reads,
generates, or outputs secret values.

It does not install External Secrets Operator, create a SecretStore or
ClusterSecretStore, provision provider credentials or IAM access, create a
namespace, or configure the dependent workload.

## Prerequisites

1. Install External Secrets Operator with the `external-secrets.io/v1` CRD.
2. Create the target namespace and a reachable SecretStore or
   ClusterSecretStore separately.
3. Create one provider-side secret containing the named properties required by
   the workload. Terraform only receives the remote key and property names.

## Usage

```hcl
module "application_secret" {
  source = "dasmeta/shared/any//modules/external-secret"

  name      = "application-database"
  namespace = "application"

  secret_store = {
    name = "application-store"
  }

  remote_key = "application/database"

  target = {
    name = "application-database"
    type = "kubernetes.io/basic-auth"
  }

  mappings = [
    {
      secret_key      = "username"
      remote_property = "username"
    },
    {
      secret_key      = "password"
      remote_property = "password"
    },
  ]
}
```

`kubernetes.io/basic-auth` is useful when a database operator needs a Secret
with `username` and `password` keys. Use the smallest mapping list required by
the workload; do not use Terraform to copy secret values.

## Operations

`kubectl_manifest` confirms that the ExternalSecret resource was accepted; it
does not wait for its provider sync. Before deploying a consumer, wait for its
Ready condition:

```sh
kubectl wait --for=condition=Ready \
  externalsecret/application-database \
  --namespace application --timeout=5m
```

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
| [kubectl_manifest.external_secret](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_annotations"></a> [annotations](#input\_annotations) | Additional annotations applied to the ExternalSecret resource. | `map(string)` | `{}` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Additional labels applied to the ExternalSecret resource. | `map(string)` | `{}` | no |
| <a name="input_mappings"></a> [mappings](#input\_mappings) | Explicit provider-property to Kubernetes Secret-key mappings. | <pre>list(object({<br/>    secret_key      = string # Key written to the target Kubernetes Secret.<br/>    remote_property = string # Property read from the common provider-side remote key.<br/>  }))</pre> | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | ExternalSecret resource name. | `string` | n/a | yes |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Existing namespace containing the ExternalSecret and target Secret. | `string` | n/a | yes |
| <a name="input_refresh_interval"></a> [refresh\_interval](#input\_refresh\_interval) | Periodic ExternalSecret refresh interval as a Go duration string. | `string` | `"1h"` | no |
| <a name="input_remote_key"></a> [remote\_key](#input\_remote\_key) | Provider-side secret identifier that contains every mapped property. | `string` | n/a | yes |
| <a name="input_secret_store"></a> [secret\_store](#input\_secret\_store) | Existing External Secrets Operator store reference. | <pre>object({<br/>    name = string                          # Existing SecretStore or ClusterSecretStore name.<br/>    kind = optional(string, "SecretStore") # Store resource kind used for retrieval.<br/>  })</pre> | n/a | yes |
| <a name="input_target"></a> [target](#input\_target) | Target Kubernetes Secret and bounded ExternalSecret lifecycle policy. | <pre>object({<br/>    name            = string                     # Kubernetes Secret name to create or manage.<br/>    type            = optional(string, "Opaque") # Kubernetes Secret type, for example kubernetes.io/basic-auth.<br/>    creation_policy = optional(string, "Owner")  # ESO target creation and ownership policy.<br/>    deletion_policy = optional(string, "Retain") # ESO behavior when provider data is removed.<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_external_secret_name"></a> [external\_secret\_name](#output\_external\_secret\_name) | ExternalSecret resource name. |
| <a name="output_target_secret_name"></a> [target\_secret\_name](#output\_target\_secret\_name) | Kubernetes Secret name managed by the ExternalSecret. |
<!-- END_TF_DOCS -->
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | ~> 1.14 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_kubectl"></a> [kubectl](#provider\_kubectl) | ~> 1.14 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [kubectl_manifest.external_secret](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_annotations"></a> [annotations](#input\_annotations) | Additional annotations applied to the ExternalSecret resource. | `map(string)` | `{}` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Additional labels applied to the ExternalSecret resource. | `map(string)` | `{}` | no |
| <a name="input_mappings"></a> [mappings](#input\_mappings) | Explicit provider-property to Kubernetes Secret-key mappings. | <pre>list(object({<br/>    secret_key      = string # Key written to the target Kubernetes Secret.<br/>    remote_property = string # Property read from the common provider-side remote key.<br/>  }))</pre> | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | ExternalSecret resource name. | `string` | n/a | yes |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Existing namespace containing the ExternalSecret and target Secret. | `string` | n/a | yes |
| <a name="input_refresh_interval"></a> [refresh\_interval](#input\_refresh\_interval) | Periodic ExternalSecret refresh interval as a Go duration string. | `string` | `"1h"` | no |
| <a name="input_remote_key"></a> [remote\_key](#input\_remote\_key) | Provider-side secret identifier that contains every mapped property. | `string` | n/a | yes |
| <a name="input_secret_store"></a> [secret\_store](#input\_secret\_store) | Existing External Secrets Operator store reference. | <pre>object({<br/>    name = string                          # Existing SecretStore or ClusterSecretStore name.<br/>    kind = optional(string, "SecretStore") # Store resource kind used for retrieval.<br/>  })</pre> | n/a | yes |
| <a name="input_target"></a> [target](#input\_target) | Target Kubernetes Secret and bounded ExternalSecret lifecycle policy. | <pre>object({<br/>    name            = string                     # Kubernetes Secret name to create or manage.<br/>    type            = optional(string, "Opaque") # Kubernetes Secret type, for example kubernetes.io/basic-auth.<br/>    creation_policy = optional(string, "Owner")  # ESO target creation and ownership policy.<br/>    deletion_policy = optional(string, "Retain") # ESO behavior when provider data is removed.<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_external_secret_name"></a> [external\_secret\_name](#output\_external\_secret\_name) | ExternalSecret resource name. |
| <a name="output_target_secret_name"></a> [target\_secret\_name](#output\_target\_secret\_name) | Kubernetes Secret name managed by the ExternalSecret. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
