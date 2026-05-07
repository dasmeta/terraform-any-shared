# Module Interface Contract

## Scope
This contract defines expected interface behavior changes for:
- `modules/istio`
- `modules/gateway-api-crds`

## `modules/istio` contract changes

### New capability
- Consumers can independently set image source configuration for Istio:
  - `base`
  - `istiod`
  - `gateway`

### Compatibility rules
- Existing consumers using defaults continue to work without additional inputs.
- Overrides are optional per component.
- If an override block is supplied, required fields in that block must be complete.

### Validation expectations
- Incomplete component overrides must fail with clear error context.
- Single-component override must not change defaults of non-overridden components.

## `modules/gateway-api-crds` contract changes

### Version contract update
- Module defaults move to latest approved stable Gateway API CRD release.
- `version` and `crdsList` must represent one consistent release contract.

### Documentation contract update
- README must include an explicit upgrade workflow:
  1. update CRD YAML source,
  2. update `version`,
  3. update `crdsList`,
  4. validate with module checks/examples.

### File lifecycle contract
- `locales.tf` is removed if unused; removal must not alter behavior beyond intended version changes.

## Non-goals
- No expansion into unrelated modules.
- No unrestricted pass-through of all upstream chart values.
