# Module Interface Contract: Helm Archive Chart Sources and Kiali Apply Readiness

## Istio Chart Fields

The following existing fields accept either repository-backed chart names or direct HTTP(S) chart archive URLs:

- `configs.base.chart`
- `configs.istiod.chart`
- `configs.gateway.ingress_gateways[*].chart`
- `configs.gateway.api_resources.chart`

### Repository-backed Chart Name Contract

```hcl
configs = {
  chart = {
    repository = "https://istio-release.storage.googleapis.com/charts"
    version    = "1.29.2"
  }

  base = {
    chart = "base"
  }
}
```

Expected behavior:

- `helm_release.istio_base.chart` receives `"base"`.
- `helm_release.istio_base.repository` receives the component repository override or `configs.chart.repository`.
- `helm_release.istio_base.version` receives the component version override or `configs.chart.version`.

### Direct HTTP(S) Chart Archive Contract

```hcl
configs = {
  base = {
    chart = "https://istio-release.storage.googleapis.com/charts/base-1.29.2.tgz"
  }
}
```

Expected behavior:

- `helm_release.istio_base.chart` receives the URL.
- `helm_release.istio_base.repository` is `null`.
- `helm_release.istio_base.version` is `null`.

This same contract applies to istiod, each ingress gateway item, and Gateway API resources.

## Kiali Operator Chart Field

The existing `configs.operator.chart` field in `modules/kiali` accepts either a repository-backed chart name or direct HTTP(S) chart archive URL.

### Direct HTTP(S) Kiali Chart Archive Contract

```hcl
configs = {
  operator = {
    chart = "https://kiali.org/helm-charts/kiali-operator-2.25.0.tgz"
  }
}
```

Expected behavior:

- `helm_release.operator.chart` receives the URL.
- `helm_release.operator.repository` is `null`.
- `helm_release.operator.version` is `null`.

When the same configuration is passed through `modules/istio` as `configs.kiali.operator.chart`, the delegated `modules/kiali` behavior is identical.

## Kiali Custom Resource Readiness

When `configs.cr.enabled` resolves to true in `modules/kiali`, the module creates `kubectl_manifest.this` with:

```hcl
wait = true
```

Expected behavior:

- Terraform waits for the Kiali custom resource readiness signal during apply.
- No additional consumer input is required.
- If the CR is disabled, no Kiali manifest resource is created.

## Compatibility Rules

- Existing default usage remains valid.
- Existing repository-backed chart overrides remain valid.
- Existing `chart_repository` and `chart_version` values are ignored only when the matching chart value is an HTTP(S) URL.
- No migration is required for consumers who do not use direct chart archive URLs.
