# Istiod and Gateway with 2 Replicas

This example shows Istiod and a Gateway API gateway each configured for **2 replicas**, similar to `terraform-aws-eks/examples/eks-with-istio-gateway-api`.

## What This Configuration Does

- **Istiod**: `autoscaleMin = 2` so the control plane runs with at least 2 replicas (HA).
- **Gateway**: `infrastructure.parameters.deployment.spec.replicas = 2` so the gateway proxy deployment has 2 replicas.

## Key Configuration

### Istiod (2 replicas minimum)

```hcl
istiod = {
  configs = {
    global = {
      proxy = {
        autoInject = "disabled"
      }
    }
    autoscaleMin = 2
  }
}
```

### Gateway (2 replicas)

```hcl
gateways = [
  {
    name             = "main"
    gatewayClassName = "istio"
    listeners = [ ... ]
    infrastructure = {
      parameters = {
        deployment = {
          spec = {
            replicas = 2
          }
        }
      }
    }
  }
]
```

## Usage

1. Set Kubernetes context: `export KUBECONFIG=/path/to/your/k8s.kubeconfig` and `export KUBE_CONFIG_PATH=$KUBECONFIG`.
2. Run: `terraform init`, `terraform plan`, `terraform apply`.
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.0 |
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

No inputs.

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
