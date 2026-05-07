# custom-chart-and-image-overrides

This example demonstrates how to set custom chart versions and image sources
for Istio components and the gateway-api chart, and how to include Kiali
customization in the same configuration.

It intentionally uses the module's current default values, so behavior should
match default module output while showing the full override structure.

Overrides shown:
- `configs.chart` (`repository`, `version`) global fallback for Istio charts
- `configs.image` (`registry`, `namespace`, `tag`) shared across Istio components
- `configs.base.repository/version` local chart override precedence over `configs.chart`
- `configs.istiod.repository/version` local chart override precedence over `configs.chart`
- `configs.gateway.ingress_gateways[*].repository/version` local chart override precedence over `configs.chart`
- `configs.gateway.api_resources.chart_version`
- `configs.kiali.operator.chart_repository/chart_version` Kiali operator chart source/version
- `configs.kiali.operator.image` shared `registry`/`namespace`/`tag` plus `repository.operator/server` image names
- `configs.kiali.cr.external_services.prometheus/grafana` Kiali observability integration settings

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.0 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | ~> 1.14 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | 2.17.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_this"></a> [this](#module\_this) | ../.. | n/a |

## Resources

| Name | Type |
|------|------|
| [helm_release.http_echo](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |

## Inputs

No inputs.

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
