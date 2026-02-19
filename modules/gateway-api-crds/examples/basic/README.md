# Gateway API CRDs Basic Example

This example demonstrates how to install Kubernetes Gateway API CRDs using the `gateway-api-crds` module.

## What This Example Does

- Installs Gateway API CRDs from the official Kubernetes SIGs Gateway API repository
- Uses the default version (v1.4.1) or allows you to specify a custom version
- Installs all CRDs required for Gateway API, including:
  - Gateway
  - HTTPRoute
  - GRPCRoute
  - TCPRoute
  - TLSRoute
  - UDPRoute
  - And related resources

## Configuration

The example uses default values, which means:
- Version: `v1.4.1` (latest stable as of module creation)

To use a different version, uncomment and modify the `crd_version` parameter in `1-example.tf`:

```hcl
module "gateway_api_crds" {
  source = "../.."

  crd_version = "v1.1.0"  # or any other version
}
```

## How to Run This Example

1. **Set up Kubernetes context**: Ensure your `KUBECONFIG` environment variable points to your Kubernetes cluster's kubeconfig file.
   ```bash
   export KUBECONFIG=/path/to/your/k8s.kubeconfig
   ```
   Or set the `kubeconfig_path` variable in `0-setup.tf` if you prefer not to use environment variables.

2. **Initialize Terraform**:
   ```bash
   terraform init
   ```

3. **Review the plan**:
   ```bash
   terraform plan
   ```

4. **Apply the configuration**:
   ```bash
   terraform apply
   ```

## Clean Up

To remove the installed CRDs:
```bash
terraform destroy
```

**Note**: Removing CRDs will also remove all Gateway API resources (Gateways, Routes, etc.) that depend on them. Use with caution in production environments.
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3 |
| <a name="requirement_http"></a> [http](#requirement\_http) | ~> 3.0 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | ~> 1.14 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_gateway_api_crds"></a> [gateway\_api\_crds](#module\_gateway\_api\_crds) | ../.. | n/a |

## Resources

No resources.

## Inputs

No inputs.

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
