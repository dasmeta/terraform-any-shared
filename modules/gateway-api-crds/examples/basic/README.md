# Gateway API CRDs Basic Example

This example demonstrates how to install Kubernetes Gateway API CRDs using the `gateway-api-crds` module.

## What This Example Does

- Installs Gateway API CRDs from a vendored `standard-install.yaml` release file in the module
- Uses the module defaults (`configs.version` + `configs.crdsList`) unless overridden
- Supports pinning a specific CRD release and explicit CRD key list for reproducible upgrades

## Configuration

The example currently uses module defaults from `modules/gateway-api-crds/variables.tf`:
- `configs.version = "v1.5.1"`
- `configs.crdsList = [...]` (explicit manifest keys)

To use an explicit version/list override in this example, set `configs` in `1-example.tf`:

```hcl
module "this" {
  source = "../.."

  configs = {
    version = "v1.5.1"
    crdsList = [
      "/apis/apiextensions.k8s.io/v1/customresourcedefinitions/backendtlspolicies.gateway.networking.k8s.io",
      "/apis/apiextensions.k8s.io/v1/customresourcedefinitions/gatewayclasses.gateway.networking.k8s.io",
      # ... keep list in sync with the selected release file
    ]
  }
}
```

## How To Upgrade CRDs And Module Defaults

Use this flow when bumping to a new Gateway API release.

### 1) Pick and download the new CRD release

Release source:
- [Gateway API releases](https://github.com/kubernetes-sigs/gateway-api/releases)

Download `standard-install.yaml` for the target tag:

```bash
VERSION="v1.5.1"
curl -fsSL "https://github.com/kubernetes-sigs/gateway-api/releases/download/${VERSION}/standard-install.yaml" \
  -o "modules/gateway-api-crds/files/${VERSION}-standard-install.yaml"
```

### 2) Set `configs.version`

Update the module default:
- file: `modules/gateway-api-crds/variables.tf`
- field: `configs.version`

Example:

```hcl
version = optional(string, "v1.5.1")
```

### 3) Extract CRD/policy keys from the downloaded file

The module uses these keys:

```hcl
data.kubectl_file_documents.gateway_api_crds.manifests[each.key]
```

So `configs.crdsList` must contain keys in the exact path format used by the YAML documents.

You can extract them with:

```bash
python3 - <<'PY'
from pathlib import Path
version = "v1.5.1"
path = Path(f"modules/gateway-api-crds/files/{version}-standard-install.yaml")
text = path.read_text()
for doc in [d for d in text.split("\n---\n") if d.strip()]:
    api = kind = name = None
    for line in doc.splitlines():
        s = line.strip()
        if s.startswith("apiVersion:") and api is None:
            api = s.split(":", 1)[1].strip()
        elif s.startswith("kind:") and kind is None:
            kind = s.split(":", 1)[1].strip()
        elif s.startswith("name:") and name is None:
            name = s.split(":", 1)[1].strip().strip('"')
    if kind == "CustomResourceDefinition":
        print(f"/apis/{api.lower()}/customresourcedefinitions/{name}")
    elif kind == "ValidatingAdmissionPolicy":
        print(f"/apis/{api.lower()}/validatingadmissionpolicys/{name}")
    elif kind == "ValidatingAdmissionPolicyBinding":
        print(f"/apis/{api.lower()}/validatingadmissionpolicybindings/{name}")
PY
```

### 4) Set `configs.crdsList` with extracted keys

Update:
- file: `modules/gateway-api-crds/variables.tf`
- field: `configs.crdsList`

Keep it strictly aligned with the selected `configs.version` file.

### 5) Update the basic example to match

Update:
- `modules/gateway-api-crds/examples/basic/1-example.tf`

Set `configs.version` and `configs.crdsList` to the same values you want users to copy.

### 6) Validate

```bash
cd modules/gateway-api-crds/examples/basic
tofu init -backend=false -input=false
tofu validate
```

If validation fails with missing manifest keys, `configs.crdsList` and the selected release file are out of sync.

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
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | ~> 1.14 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_this"></a> [this](#module\_this) | ../.. | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_configs"></a> [configs](#input\_configs) | The configs for the module. This is for the example to show the crds\_keys output | `any` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_crds_keys"></a> [crds\_keys](#output\_crds\_keys) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
