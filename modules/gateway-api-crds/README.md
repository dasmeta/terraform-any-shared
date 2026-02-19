# Gateway API CRDs Module

This Terraform module installs Kubernetes Gateway API Custom Resource Definitions (CRDs) using the official manifests from the [Kubernetes SIGs Gateway API repository](https://github.com/kubernetes-sigs/gateway-api).

## Features

- Installs Gateway API CRDs from official releases
- Uses server-side apply for reliable CRD installation
- Handles multi-document YAML manifests automatically
- Supports version pinning for reproducible deployments

## Usage

```hcl
module "gateway_api_crds" {
  source = "../gateway-api-crds"

  crd_version = "v1.4.1"
}
```

## Requirements

| Name      | Version |
| --------- | ------- |
| terraform | ~> 1.3  |
| kubectl   | ~> 1.14 |
| http      | ~> 3.0  |

## Providers

| Name    | Version |
| ------- | ------- |
| kubectl | ~> 1.14 |
| http    | ~> 3.0  |

## Inputs

| Name        | Description                                                           | Type     | Default    | Required |
| ----------- | --------------------------------------------------------------------- | -------- | ---------- | :------: |
| crd_version | The version of the Gateway API CRDs to install (e.g., v1.4.1, v1.1.0) | `string` | `"v1.4.1"` |    no    |

## Outputs

| Name      | Description                                            |
| --------- | ------------------------------------------------------ |
| manifests | Map of kubectl_manifest resources for Gateway API CRDs |

## How It Works

1. Downloads the `standard-install.yaml` manifest from the Gateway API GitHub releases
2. Uses `kubectl_file_documents` data source to split multi-document YAML into individual documents
3. Creates individual `kubectl_manifest` resources for each CRD
4. Uses server-side apply with `wait = true` for reliable installation

## Notes

- The CRDs are installed cluster-wide (no namespace required)
- This module is typically used as a dependency before installing Gateway API controllers (e.g., Istio Gateway API controller)
- The module handles all CRDs defined in the standard install manifest, including Gateway, HTTPRoute, GRPCRoute, TCPRoute, TLSRoute, UDPRoute, and related resources
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3 |
| <a name="requirement_http"></a> [http](#requirement\_http) | ~> 3.0 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | ~> 1.14 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_http"></a> [http](#provider\_http) | ~> 3.0 |
| <a name="provider_kubectl"></a> [kubectl](#provider\_kubectl) | ~> 1.14 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [kubectl_manifest.gateway_api_crds](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [http_http.gateway_api_crds](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |
| [kubectl_file_documents.gateway_api_crds](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/data-sources/file_documents) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_crd_version"></a> [crd\_version](#input\_crd\_version) | The version of the Gateway API CRDs to install (e.g., v1.4.1, v1.1.0) | `string` | `"v1.4.1"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_manifests"></a> [manifests](#output\_manifests) | Map of kubectl\_manifest resources for Gateway API CRDs |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
