# Module Interface Contract

## Scope
This contract covers version-default changes for:
- `modules/istio`
- `modules/gateway-api-crds`
- `modules/kiali`

No input or output shape changes are introduced. The consumer-facing interface is unchanged; only default values move.

## `modules/istio` contract changes

### Default deltas
- Fallback `configs.chart.version`: `1.29.2` -> `1.30.3`
- Kiali operator fallback `chart_version`: `2.25.0` -> `2.29.0`
- gateway-api resources chart fallback `chart_version`: unchanged (`0.1.7`)

### Compatibility rules
- Consumers who set `configs.chart.version` or per-component versions are unaffected (pins win).
- No new required inputs; no removed inputs; no output changes.

## `modules/gateway-api-crds` contract changes

### Version contract update
- Default `version`: `v1.5.1` -> `v1.6.1`.
- `crdsList` gains `tcproutes` and `udproutes` (GA in the v1.6 standard channel); the full set is now 12 documents (10 CRDs + ValidatingAdmissionPolicy + ValidatingAdmissionPolicyBinding).
- New `files/v1.6.1-standard-install.yaml` added; `files/v1.5.1-standard-install.yaml` retained for rollback.

### Compatibility rules
- `version` and `crdsList` MUST describe one consistent release; `crdsList` MUST cover every document in the selected manifest.
- Consumers who pin `version`/`crdsList` are unaffected.

### Upgrade safety
- Upgrade is in-place via server-side apply; the `safe-upgrades` ValidatingAdmissionPolicy validates the change. No destroy/recreate.

## `modules/kiali` contract changes

### Default delta
- `chart_version`: `2.25.0` -> `2.29.0`.

### Compatibility rules
- Backward compatible; consumers who pin the Kiali version are unaffected.

## Cross-cutting
- No provider version constraints change (`versions.tf` untouched).
- No breaking changes; no interface widening.
