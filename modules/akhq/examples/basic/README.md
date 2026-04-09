# basic

Deploys AKHQ with placeholder Kafka bootstrap and Ingress annotations suitable for AWS LBC-style ALB.

Use `terraform.tfvars` (gitignored) for `security.basic_auth_password` in real environments.

Prerequisites:

- Kubernetes cluster
- Kafka bootstrap reachable from the cluster
- Ingress controller matching `ingress.annotations` if Ingress stays enabled
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.5 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_akhq"></a> [akhq](#module\_akhq) | ../.. | n/a |

## Resources

No resources.

## Inputs

No inputs.

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
