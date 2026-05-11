# Data Model: Helm Archive Chart Sources and Kiali Apply Readiness

## Chart Source

Represents an existing chart string input accepted by a Helm release wrapper.

**Fields**:

- `chart`: string. Either a repository-backed chart name such as `istiod` or an HTTP(S) direct chart archive URL such as `https://istio-release.storage.googleapis.com/charts/istiod-1.29.2.tgz`.
- `repository`: optional string. Used only when `chart` is not an HTTP(S) URL.
- `version`: optional string. Used only when `chart` is not an HTTP(S) URL.

**Validation / Behavior**:

- HTTP(S) chart URLs are detected internally with a Terraform regex check.
- Repository and version values are intentionally ignored by the resource when the chart is a direct HTTP(S) URL.
- Non-HTTP(S) values keep existing repository/version fallback behavior.

## Istio Chart Source Set

Collection of chart sources controlled by `modules/istio`.

**Members**:

- `configs.base.chart`
- `configs.istiod.chart`
- `configs.gateway.ingress_gateways[*].chart`
- `configs.gateway.api_resources.chart`

**Relationships**:

- `configs.chart.repository` and `configs.chart.version` remain global fallbacks for repository-backed Istio component chart names.
- Per-component repository/version overrides remain available for repository-backed chart names.
- Direct URL detection is evaluated separately for each gateway list item.

## Kiali Operator Chart Source

Chart source controlled by `modules/kiali` and delegated from `modules/istio` through `configs.kiali.operator`.

**Fields**:

- `configs.operator.chart`
- `configs.operator.chart_repository`
- `configs.operator.chart_version`

**Behavior**:

- Direct HTTP(S) chart URLs suppress `chart_repository` and `chart_version` at the Helm resource.
- Default chart name keeps the default Kiali chart repository and version behavior.

## Kiali Manifest Readiness Contract

Represents apply-time readiness behavior for the Kiali custom resource.

**Fields**:

- `configs.cr.enabled`: controls whether the `kubectl_manifest` resource exists.
- `kubectl_manifest.this.wait`: always `true` when the resource exists.

**Behavior**:

- Enabled Kiali CR creation waits for readiness.
- Disabled Kiali CR creation produces no manifest resource and no new wait behavior.

## Direct Chart Sources Example

Example configuration that demonstrates direct chart archive URL usage.

**Responsibilities**:

- Demonstrate Istio base, istiod, optional gateway, Gateway API resource chart, and Kiali operator chart archive sources using the original upstream chart package URLs.
- Keep the helper `http-echo` chart repository-backed because it is not part of the direct `.tgz` source behavior under test.
- Avoid registry-specific derivation logic so the example stays focused on direct `.tgz` source handling.
- Avoid generated Terraform runtime artifacts and customer-specific identifiers in committed content.
