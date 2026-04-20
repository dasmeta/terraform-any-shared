# basic

This example documents the baseline Argo CD deployment path for the module using
an AWS ALB Ingress and an existing `argocd-secret` managed outside this Terraform
run (recommended for production).

Prerequisites:

- an existing Kubernetes cluster reachable through the Helm and Kubernetes providers
- AWS Load Balancer Controller installed in the cluster
- a consumer-managed ALB + DNS + TLS strategy (annotations are examples only)
- an existing `argocd-secret` in the target namespace when `use_existing_admin_secret=true`

The module keeps the interface intentionally narrow. It does not expose a
generic Helm values pass-through, does not manage AWS resources, and does not
manage certificate issuance.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_argocd"></a> [argocd](#module\_argocd) | ../.. | n/a |

## Resources

No resources.

## Inputs

No inputs.

## Outputs

No outputs.
<!-- END_TF_DOCS -->
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_argocd"></a> [argocd](#module\_argocd) | ../.. | n/a |

## Resources

No resources.

## Inputs

No inputs.

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
