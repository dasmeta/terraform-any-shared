# Data Model: Istio and Gateway API Upgrade Configurability

## Entity: Istio Component Image Override Set
- **Description**: Consumer-facing configuration object used to override image source details independently for `base`, `istiod`, and `gateway`.
- **Fields**:
  - `base`: component image override object
  - `istiod`: component image override object
  - `gateway`: component image override object
- **Validation rules**:
  - Each component override is optional.
  - If a component override is provided, required image source fields for that component must be complete.
  - Missing/partial required fields in a provided override must produce a clear failure.
- **Relationships**:
  - Feeds Istio Helm values rendering behavior.

## Entity: Component Image Override
- **Description**: Canonical structure for one component image source.
- **Fields**:
  - `repository`: image registry/repository source
  - `image`: image name or identifier
- **Validation rules**:
  - `repository` and `image` are required together when override is present.
  - Empty strings are invalid.

## Entity: Istio Version Baseline
- **Description**: Module default version set used by Istio and Gateway API chart-managed components.
- **Fields**:
  - `base_chart_version`
  - `istiod_chart_version`
  - `gateway_chart_version`
  - any additional version selectors currently used in module defaults
- **Validation rules**:
  - Values must reference stable versions accepted by maintainers.
  - Defaults remain backwards compatible for consumers who do not set custom versions.

## Entity: Gateway API CRD Version Contract
- **Description**: Configuration contract for selecting and applying Gateway API CRD artifacts.
- **Fields**:
  - `version`: target CRD release selector
  - `crdsList`: list of CRD artifacts expected for the selected version
- **Validation rules**:
  - `crdsList` must match the selected `version` contract.
  - Outdated/incomplete list entries are invalid for the selected version baseline.

## Entity: CRD Upgrade Procedure
- **Description**: Documented maintainer process describing how to upgrade CRD YAML and keep module config in sync.
- **State transitions**:
  1. Identify target stable CRD release.
  2. Update CRD source YAML file(s).
  3. Update module `version` and `crdsList` defaults accordingly.
  4. Run validation checks and confirm example usage still succeeds.
  5. Publish README guidance updates with resulting version contract.
