# Upgrading Istio to 1.32

This module updates its existing Helm releases in place. An installation on **1.30 must upgrade to 1.31.x before 1.32.0**, using two separate Terraform applies. Fresh installations can use the 1.32.0 default directly; older installations must also pass through each intervening minor version.

This follows Istio's [in-place upgrade rules](https://istio.io/latest/docs/setup/upgrade/canary/#before-you-upgrade) and [Helm upgrade workflow](https://istio.io/latest/docs/setup/upgrade/helm/#in-place-upgrade). Revision-based canary upgrades have different rules and require a separate migration workflow; changing this module's version does not create a canary automatically.

## 1. Apply the intermediate 1.31 release

When selecting the new Terraform module version, also pin the intermediate Istio version in the **same configuration change**, before planning. Inside your existing `configs`, set the following fields while retaining all other settings:

```hcl
chart = {
  version = "1.31.4"
}
image = {
  tag = "1.31.4"
}
```

`1.31.4` is an example intermediate patch; use an appropriate supported 1.31.x patch for your environment. Align all effective chart/image versions, including:

- Component pins: `configs.base.version`, `configs.istiod.version`, and every `configs.gateway.ingress_gateways[*].version` override the global chart version.
- Direct `.tgz` chart URLs: update the base, istiod, and optional gateway URLs to 1.31.x; those releases ignore repository/version fields.
- Raw Helm values: existing `global.tag`, image, or Gateway infrastructure overrides can supersede the module defaults. Ensure custom registries contain the matching images.

Use the **target release's** `istioctl` binary, review the plan for aligned versions, and apply from your consumer configuration directory:

```sh
istioctl x precheck --from-version 1.30
terraform plan -out=istio-upgrade.tfplan
terraform apply istio-upgrade.tfplan
istioctl version
istioctl proxy-status
```

Before proceeding, verify all istiod replicas and gateway proxies run 1.31.x and are ready, proxy configuration is synchronized, and existing routes, endpoints, and TLS/authentication checks pass. Roll out sidecar workloads as needed to update their proxies; a control-plane apply alone does not restart them. Check controller-managed Gateway API deployments as well as Helm-managed gateways, including any pinned gateway images.

## 2. Apply the 1.32 default

After the intermediate rollout is healthy, remove the temporary `configs.chart.version` and `configs.image.tag` pins to inherit the new chart/image defaults, or explicitly set both to `1.32.0`. Also update any component pins, raw values, and direct chart URLs listed above.

Switch to the 1.32.0 `istioctl`, then repeat the plan/apply and verification sequence:

```sh
istioctl x precheck --from-version 1.31
terraform plan -out=istio-upgrade.tfplan
terraform apply istio-upgrade.tfplan
istioctl version
istioctl proxy-status
```

Verify all control-plane and gateway replicas run 1.32.0, update remaining sidecars, and repeat endpoint and TLS/authentication tests. Retain the intermediate pin and investigate if its rollout or checks fail; do not proceed to 1.32 while 1.31 is unhealthy.

The Istio default change does not upgrade Kiali or the separately managed Gateway API CRD bundle. Review those components independently. If you maintain custom EnvoyFilters, review them against each target Istio/Envoy release before upgrading.
