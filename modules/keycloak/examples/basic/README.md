# basic

This example documents the baseline Keycloak deployment path for the module
using raw password inputs that are converted into module-managed Kubernetes
Secrets.

Prerequisites:

- an existing Kubernetes cluster reachable through the Helm and Kubernetes providers
- a consumer-managed external PostgreSQL database
- a consumer-managed ingress controller if `ingress.enabled` remains `true`

The module keeps the interface intentionally narrow. It does not expose a
generic Helm values pass-through, does not provision the database, and does not
manage ingress controllers or certificate issuance.

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
| <a name="module_keycloak"></a> [keycloak](#module\_keycloak) | ../.. | n/a |
| <a name="module_keycloak_existing_secrets"></a> [keycloak\_existing\_secrets](#module\_keycloak\_existing\_secrets) | ../.. | n/a |

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
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_keycloak"></a> [keycloak](#module\_keycloak) | ../.. | n/a |

## Resources

No resources.

## Inputs

No inputs.

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
