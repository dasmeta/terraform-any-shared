# Gateway API CRDs Module

Use this module when a cluster needs the Gateway API CRDs installed ahead of
controllers or gateways that depend on them.

This Terraform module installs Kubernetes Gateway API Custom Resource Definitions (CRDs) using vendored official manifests from the [Kubernetes SIGs Gateway API repository](https://github.com/kubernetes-sigs/gateway-api).

## Features

- Installs Gateway API CRDs from official releases
- Uses server-side apply for reliable CRD installation
- Handles multi-document YAML manifests automatically
- Supports explicit `version` and `crdsList` pinning for reproducible deployments

## Usage

```hcl
module "gateway_api_crds" {
  source  = "dasmeta/shared/any//modules/gateway-api-crds"
  # version = "x.y.z" # Check https://registry.terraform.io/modules/dasmeta/shared/any/latest/submodules/gateway-api-crds and set the version
}
```

## How It Works

1. Reads the `files/<version>-standard-install.yaml` manifest from this module.
2. Uses `kubectl_file_documents` data source to split multi-document YAML into individual documents.
3. Creates individual `kubectl_manifest` resources for each selected entry in `configs.crdsList`.
4. Uses server-side apply with `wait = true` for reliable installation.

## CRD Upgrade Workflow (`version` and `crdsList`)

1. Pick the target release tag from:
   - https://github.com/kubernetes-sigs/gateway-api/releases
2. Pull CRDs from the selected release and vendor them into this module:

```bash
VERSION="v1.5.1" # we have the latest one used so make sure you set the version tag to which you are updating to
curl -fsSL "https://github.com/kubernetes-sigs/gateway-api/releases/download/${VERSION}/standard-install.yaml" \
  -o "modules/gateway-api-crds/files/${VERSION}-standard-install.yaml"
```

3. Get the manifest keys from module output `crds_keys` (from `outputs.tf`):

```bash
cd modules/gateway-api-crds/examples/basic
terraform init
terraform plan -var='configs={version="${VERSION}", crdsList=[]}'
```

Copy the resulting list values into `configs.crdsList` of variables.tf.

4. Set module defaults in `modules/gateway-api-crds/variables.tf`:
   - update `configs.version` to the new tag/version from $VERSION
   - replace `configs.crdsList` with keys from `crds_keys` of step
5. Update example consumer config in `modules/gateway-api-crds/examples/basic/1-example.tf`:
   - set `configs.version` to the same tag
   - set `configs.crdsList` to the same extracted list
6. If needed, set the same fields in real downstream usage:

```hcl
module "gateway_api_crds" {
  source = "dasmeta/shared/any//modules/gateway-api-crds"
  # version = "x.y.z"

  configs = {
    version  = "v1.5.1"
    crdsList = [
      # extracted keys here
    ]
  }
}
```

7. Validate the upgrade:
   - `terraform fmt -recursive modules/gateway-api-crds`
   - `cd modules/gateway-api-crds/examples/basic && terraform init -backend=false -input=false && terraform validate`

## Notes

- `version` and `crdsList` must always be updated together. A mismatched pair will fail when `kubectl_manifest` looks up missing keys in `data.kubectl_file_documents.gateway_api_crds.manifests`.
- The CRDs are installed cluster-wide (no namespace required)
- This module is typically used as a dependency before installing Gateway API controllers (e.g., Istio Gateway API controller)
- When using this module there is no need(if there is no special need to like when we upgrade the crds based on above flow) to set/change/customize the config variables, as config variables strictly connected to what version crds file we have pulled
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | ~> 1.14 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_kubectl"></a> [kubectl](#provider\_kubectl) | ~> 1.14 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [kubectl_manifest.gateway_api_crds](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_file_documents.gateway_api_crds](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/data-sources/file_documents) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_configs"></a> [configs](#input\_configs) | The version of the Gateway API CRDs and the list of CRDs to install. NOTE: This config supposed to be changed when we want to upgrade the Gateway API CRDs version. | <pre>object({<br/>    version = optional(string, "v1.5.1")<br/>    crdsList = optional(list(string), [<br/>      "/apis/apiextensions.k8s.io/v1/customresourcedefinitions/backendtlspolicies.gateway.networking.k8s.io",<br/>      "/apis/apiextensions.k8s.io/v1/customresourcedefinitions/gatewayclasses.gateway.networking.k8s.io",<br/>      "/apis/apiextensions.k8s.io/v1/customresourcedefinitions/gateways.gateway.networking.k8s.io",<br/>      "/apis/apiextensions.k8s.io/v1/customresourcedefinitions/grpcroutes.gateway.networking.k8s.io",<br/>      "/apis/apiextensions.k8s.io/v1/customresourcedefinitions/httproutes.gateway.networking.k8s.io",<br/>      "/apis/apiextensions.k8s.io/v1/customresourcedefinitions/listenersets.gateway.networking.k8s.io",<br/>      "/apis/apiextensions.k8s.io/v1/customresourcedefinitions/referencegrants.gateway.networking.k8s.io",<br/>      "/apis/apiextensions.k8s.io/v1/customresourcedefinitions/tlsroutes.gateway.networking.k8s.io",<br/>      "/apis/admissionregistration.k8s.io/v1/validatingadmissionpolicys/safe-upgrades.gateway.networking.k8s.io",<br/>      "/apis/admissionregistration.k8s.io/v1/validatingadmissionpolicybindings/safe-upgrades.gateway.networking.k8s.io",<br/>    ])<br/>  })</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_crds_keys"></a> [crds\_keys](#output\_crds\_keys) | Map of dependencies for Gateway API CRDs, can be used to identify which CRDs are included in the manifest |
| <a name="output_manifests"></a> [manifests](#output\_manifests) | Map of kubectl\_manifest resources for Gateway API CRDs |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
