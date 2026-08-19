# Data Model: Upgrade Istio Stack Tooling Versions

## Entity: Istio Version Baseline
- **Description**: The default chart version used by Istio `base`/`istiod`/`gateway` and the source of the derived istiod/proxy image tags when no explicit tag is set.
- **Fields**:
  - `chart.version`: fallback chart version for all Istio components (`1.30.3`)
- **Validation rules**:
  - Must reference a published, stable Istio chart version.
  - Consumers who set `configs.chart.version` or per-component versions override the fallback.
  - Defaults remain backward-compatible for consumers who do not pin versions.
- **Relationships**:
  - Feeds the `base`/`istiod`/`gateway` Helm releases and derived image tags.

## Entity: Gateway API CRD Version Contract
- **Description**: The `version` + `crdsList` pair that jointly selects and applies one Gateway API CRD release.
- **Fields**:
  - `version`: target CRD release selector (`v1.6.1`)
  - `crdsList`: document-key list for every resource in the matching `files/<version>-standard-install.yaml`
- **Validation rules**:
  - `crdsList` MUST match the document set of the selected `version` (12 documents for v1.6.1: 10 CRDs + 1 ValidatingAdmissionPolicy + 1 ValidatingAdmissionPolicyBinding).
  - The referenced `files/<version>-standard-install.yaml` MUST exist in the module.
  - Retained document-key paths remain valid only while the upstream CRD/VAP `apiVersion`s are unchanged (confirmed for v1.5.1 -> v1.6.1).
- **Relationships**:
  - Consumed by `kubectl_manifest` server-side apply of each document.

## Entity: Kiali Operator Version
- **Description**: The Kiali operator chart version and the source of the derived `v<version>` operator/server image tags.
- **Fields**:
  - `chart_version`: Kiali operator chart version (`2.29.0`)
- **Validation rules**:
  - Must reference a published Kiali operator chart version.
  - Backward-compatible for consumers who do not pin the Kiali version.

## Entity: Gateway API Resources Chart Version
- **Description**: The dasmeta `gateway-api` chart used to render Gateway/Route resources.
- **Fields**:
  - `chart_version`: resources chart version (`0.1.7`, unchanged)
- **Validation rules**:
  - Left unchanged because chart content is unchanged; only bump when templates/values change.

## State transitions: In-place CRD upgrade (v1.5.1 -> v1.6.1)
1. New `files/v1.6.1-standard-install.yaml` is added; `version` default set to `v1.6.1`.
2. `crdsList` extended with `tcproutes` and `udproutes`.
3. On apply, each of the 12 documents is server-side applied.
4. The `safe-upgrades` ValidatingAdmissionPolicy validates the CRD changes.
5. Existing v1.5.1 CRDs are upgraded in place; the two new CRDs are created; no destroys.
