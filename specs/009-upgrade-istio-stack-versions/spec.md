# Feature Specification: Upgrade Istio Stack Tooling Versions

**Feature Branch**: `009-upgrade-istio-stack-versions`  
**Created**: 2026-07-21  
**Status**: Draft  
**Input**: User description: "upgrade the istio stack tooling to latest stable versions in the dasmeta/terraform-any-shared modules: Istio components 1.29.2 -> 1.30.3, Gateway API CRDs v1.5.1 -> v1.6.1 (tcproutes/udproutes graduated to the standard channel), and Kiali operator 2.25.0 -> 2.29.0. Verify locally on docker-desktop via the chart-direct-tgz-sources example."

## Module Context *(mandatory)*

- **Target Module Path**: `modules/istio`, `modules/gateway-api-crds`, `modules/kiali`
- **Related Files In Scope**: `modules/istio/variables.tf`, `modules/istio/examples/chart-direct-tgz-sources/1-example.tf`, `modules/gateway-api-crds/variables.tf`, `modules/gateway-api-crds/files/v1.6.1-standard-install.yaml`, `modules/kiali/variables.tf`
- **Upstream Baseline**: Helm-chart-driven deployment for Istio (`base`/`istiod`/`gateway`) and Kiali operator; managed Gateway API CRD manifests pulled from the official `kubernetes-sigs/gateway-api` release
- **Requested Interface Change**: Version-default changes only. No input/output shape changes. Gateway API `crdsList` default gains `tcproutes` and `udproutes` (now GA in the v1.6 standard channel)
- **Breaking Change / Interface Widening**: None. All changes are backward-compatible default version bumps; consumers who pin versions are unaffected

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Consume up-to-date Istio stack defaults (Priority: P1)

As a platform engineer, I can consume the modules with their default versions and get the current stable Istio (1.30.3), Gateway API CRDs (v1.6.1), and Kiali operator (2.29.0) without pinning versions myself.

**Why this priority**: Version freshness is the entire purpose of this change — it keeps the stack on supported, patched releases.

**Independent Test**: Apply the `chart-direct-tgz-sources` example against a local docker-desktop cluster and confirm istiod reports image `1.30.3` and the Gateway API CRD bundle-version is `v1.6.1`.

**Acceptance Scenarios**:

1. **Given** a consumer using module defaults, **When** the module is planned, **Then** Istio components resolve to `1.30.3`, Kiali operator to `2.29.0`, and Gateway API CRDs to `v1.6.1`.
2. **Given** a consumer that pins explicit versions, **When** the module is planned, **Then** the pinned versions are honored unchanged (no forced upgrade).

---

### User Story 2 - Gateway API v1.6 standard-channel routes (Priority: P2)

As a platform engineer, I can define `TCPRoute` and `UDPRoute` resources at `gateway.networking.k8s.io/v1` because the v1.6.1 CRD bundle installs them in the standard channel.

**Why this priority**: TCPRoute/UDPRoute graduated to GA in Gateway API v1.6.0; the module must install their CRDs so consumers can use them.

**Independent Test**: Apply the upgraded CRDs and confirm `tcproutes` and `udproutes` CRDs exist and that the gateway-api chart renders those routes at `v1`.

**Acceptance Scenarios**:

1. **Given** the v1.6.1 CRD bundle, **When** the module applies CRDs, **Then** `tcproutes` and `udproutes` CRDs are present in addition to the existing eight.
2. **Given** an in-place upgrade from v1.5.1, **When** the new CRDs are server-side applied, **Then** the `safe-upgrades` ValidatingAdmissionPolicy accepts the change.

---

### User Story 3 - Safe in-place upgrade of a running cluster (Priority: P3)

As an operator, I can upgrade an already-deployed istio stack (running v1.5.1 CRDs / Istio 1.29.2) to the new defaults in place without destroying resources.

**Why this priority**: Existing clusters must upgrade cleanly; a destroy/recreate would be an outage.

**Independent Test**: On a cluster already running the old versions, apply the upgraded example and confirm the plan is upgrade-only (no destroys) and the test app stays reachable.

**Acceptance Scenarios**:

1. **Given** a cluster on Istio 1.29.2 / CRDs v1.5.1, **When** the upgraded example is applied, **Then** the plan reports additions (new CRDs) and in-place updates but zero destroys.
2. **Given** the upgrade completes, **When** the test endpoint is requested, **Then** it continues to serve traffic through the Gateway API route.

### Edge Cases

- What happens when the running cluster already has the v1.5.1 CRDs? Server-side apply upgrades them in place; the `safe-upgrades` policy guards against unsafe schema changes.
- How does the module behave for consumers who pin `configs.chart.version` or per-component chart versions? Pins take precedence over the new defaults; no forced change.
- What happens if the gateway-api chart version is left at `0.1.7`? It stays at `0.1.7` — the chart content did not change, so it is intentionally NOT bumped; it renders routes at `v1` and remains compatible with the v1.6.1 CRDs.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `modules/gateway-api-crds` MUST default to Gateway API CRD release `v1.6.1` and ship the matching `files/v1.6.1-standard-install.yaml` manifest.
- **FR-002**: The `crdsList` default MUST include `tcproutes` and `udproutes` (GA standard-channel CRDs as of v1.6.0) so all 12 documents in the manifest are applied.
- **FR-003**: `modules/istio` MUST default the fallback chart `version` to `1.30.3` for `base`/`istiod`/`gateway` and default the Kiali operator chart fallback to `2.29.0`.
- **FR-004**: `modules/kiali` MUST default `chart_version` to `2.29.0`.
- **FR-005**: The gateway-api resources chart version MUST remain `0.1.7` (unchanged content — no gratuitous version bump).
- **FR-006**: All changes MUST preserve existing input/output interfaces; consumers pinning versions MUST be unaffected.

### Compatibility & Delivery Requirements

- **CDR-001**: In-scope modules and the local verification example (`modules/istio/examples/chart-direct-tgz-sources`) are identified.
- **CDR-002**: Upstream origins are the authoritative version source: `istio/istio` + istio-release chart storage, `kubernetes-sigs/gateway-api` releases, and `kiali.org/helm-charts`.
- **CDR-003**: Verification is performed by applying the `chart-direct-tgz-sources` example against a local docker-desktop cluster and checking deployed versions plus the test endpoint.
- **CDR-004**: No downstream migration is required; the upgrade is in-place and backward-compatible.

### Key Entities *(include if feature involves data or structured configuration)*

- **Istio Version Baseline**: The default chart version applied to Istio `base`/`istiod`/`gateway` and the derived proxy/istiod image tags.
- **Gateway API CRD Version Contract**: The `version` + `crdsList` pair that must jointly describe one CRD release (`v1.6.1` + its 12 documents).
- **Kiali Operator Version**: The operator chart version and its derived `v<version>` image tags.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Applying the documented example on docker-desktop yields istiod image `1.30.3` and Gateway API CRD bundle-version `v1.6.1` with no undocumented manual steps.
- **SC-002**: `terraform validate` passes for the affected module/example paths; `terraform plan` on an already-deployed cluster shows zero destroys.
- **SC-003**: `tcproutes` and `udproutes` CRDs are installed and the gateway-api chart renders those routes at `gateway.networking.k8s.io/v1`.
- **SC-004**: The test endpoint `http://http-echo-chart-direct-tgz-sources.localhost/ping` responds successfully after the upgrade.
