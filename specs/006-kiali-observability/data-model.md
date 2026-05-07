# Data Model: Kiali Observability For Istio

## Entity: Kiali Operator Release Configuration
- **Description**: Helm release settings used to install and manage the Kiali operator.
- **Fields**:
  - `configs.operator.enabled`
  - `configs.operator.name`
  - `configs.operator.namespace`
  - `configs.operator.chart`
  - `configs.operator.chart_version`
  - `configs.operator.create_namespace`
  - `configs.operator.atomic`
  - `configs.operator.wait`
  - `configs.operator.values`
  - `configs.operator.extra_values`
  - top-level `chart_repository`
  - top-level operator image object (`repo`, `tag`, `digest`, `allow_ad_hoc_kiali_image`)
- **Validation rules**:
  - Operator release is created only when `configs.enabled && configs.operator.enabled`.
  - Chart repository and chart name must resolve to a valid Helm chart source.

## Entity: Kiali Custom Resource Configuration
- **Description**: Structured inputs that render a `kiali.io/v1alpha1` `Kiali` resource.
- **Fields**:
  - `configs.cr.enabled`
  - `configs.cr.name`
  - `configs.cr.namespace`
  - `configs.cr.labels`
  - `configs.cr.annotations`
  - `configs.cr.auth_strategy`
  - `configs.cr.view_only_mode`
  - `configs.cr.deployment`
  - `configs.cr.external_services.prometheus.*`
  - `configs.cr.external_services.grafana.*`
  - `configs.cr.spec` (raw overlay)
- **Validation rules**:
  - CR is rendered only when `configs.enabled && configs.cr.enabled`.
  - Common Prometheus/Grafana fields are optional and merged without forcing empty values.
  - Raw `spec` overlay can override generated defaults on key conflict.

## Entity: Kiali Server Image Override
- **Description**: Optional server image override for the Kiali server deployment managed by the operator.
- **Fields**:
  - `configs.kiali.image.server.repository`
  - `configs.kiali.image.server.tag`
- **Validation rules**:
  - Either field can be set independently, but resulting deployment config must remain valid for operator reconciliation.
  - When either server image field is set, operator `allow_ad_hoc_kiali_image` must be true (explicitly or via derived default).

## Entity: Istio-to-Kiali Delegation Contract
- **Description**: Optional delegation path from `modules/istio` into `modules/kiali`.
- **Fields**:
  - `configs.kiali.enabled`
  - `configs.kiali.chart_repository`
  - `configs.kiali.chart_version`
  - `configs.kiali.image.operator.*`
  - `configs.kiali.image.server.*`
  - `configs.kiali.operator.*`
  - `configs.kiali.cr.*`
- **Validation rules**:
  - Delegation must not affect existing Istio behavior when omitted.
  - Namespace defaults flow from Istio chart namespace unless explicitly overridden in Kiali settings.

## Relationships
- `Istio-to-Kiali Delegation Contract` configures and invokes `Kiali Operator Release Configuration` and `Kiali Custom Resource Configuration`.
- `Kiali Server Image Override` mutates `Kiali Custom Resource Configuration` deployment settings and depends on `Kiali Operator Release Configuration` image policy.
