# Module Interface Contract

## Scope
This contract defines expected interface behavior for:
- `modules/kiali`
- `modules/istio` (`configs.kiali` delegation path)

## `modules/kiali` contract

### Core behavior
- Installs Kiali operator Helm release when enabled.
- Creates Kiali custom resource when enabled.
- Supports common Prometheus and Grafana integration fields in wrapper input.
- Preserves raw `spec` overlay for advanced Kiali CR settings.

### Compatibility rules
- Existing consumers can keep defaults without providing additional inputs.
- Wrapper remains opinionated and does not become unrestricted pass-through.

### Image behavior
- Operator image overrides are passed through the dedicated operator image object.
- Kiali server image overrides are applied through Kiali CR deployment settings.
- When Kiali server image override is set, operator ad-hoc image allowance must be enabled explicitly or by module-derived default.

## `modules/istio` delegation contract

### Delegation behavior
- `configs.kiali` is optional.
- When omitted, Istio behavior and rendered resources remain unchanged.
- When enabled, Istio delegates Kiali provisioning to `modules/kiali` with namespace and chart/version fallback behavior defined by wrapper logic.

### Example and documentation obligations
- `modules/istio/README.md` and `modules/kiali/README.md` must describe current delegation and standalone usage.
- `modules/istio/examples/kiali-observability` must remain aligned with delegation contract.
- `modules/istio/examples/custom-chart-and-image-overrides` must include Kiali customization usage (FR-009).

## Non-goals
- No expansion into unrelated repositories or modules.
- No conversion of the Kiali wrapper into a full mirror of all upstream chart/CR options.
