# Feature Specification: Helm Archive Chart Sources and Kiali Apply Readiness

**Feature Branch**: `007-helm-archive-kiali-wait`  
**Created**: 2026-05-11  
**Status**: Draft  
**Input**: User description: "there are already changes which have to go through speckit flow, the changes are related to using chart .tgz direct links and wait=true for kiali resource creation, this two changes should go throug speckit"

## Module Context *(mandatory)*

- **Target Module Path**: `modules/istio`, `modules/kiali`
- **Related Files In Scope**: `modules/istio/main.tf`, `modules/istio/variables.tf`, `modules/istio/README.md`, `modules/istio/examples/chart-direct-tgz-sources/`, `modules/kiali/main.tf`, `modules/kiali/variables.tf`, `modules/kiali/README.md`, affected example validation paths
- **Upstream Baseline**: Helm provider `helm_release` resources for Istio, Gateway API resource chart, and Kiali operator chart; `kubectl_manifest` resource for the Kiali custom resource
- **Requested Interface Change**: Existing chart string fields accept direct HTTP(S) `.tgz` chart archive URLs in addition to repository-backed chart names; Kiali custom resource creation waits for the applied manifest to be ready
- **Breaking Change / Interface Widening**: No breaking change. Bounded widening of accepted values for existing chart inputs; no new required variables and no broad upstream pass-through

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Use Direct Chart Archives For Istio (Priority: P1)

As a platform engineer, I can point Istio component chart fields at direct upstream `.tgz` archive URLs so deployments can consume packaged charts without requiring Helm repository index resolution during plan/apply.

**Why this priority**: This is the primary requested behavior and proves archive URL support for Istio base, istiod, ingress gateway, and Gateway API resources using the original chart sources.

**Independent Test**: Configure `configs.base.chart`, `configs.istiod.chart`, `configs.gateway.ingress_gateways[*].chart`, and `configs.gateway.api_resources.chart` with HTTP(S) `.tgz` URLs and verify Terraform validation succeeds without requiring repository/version fields for those direct chart sources.

**Acceptance Scenarios**:

1. **Given** an Istio component chart value is a direct `https://.../*.tgz` URL, **When** Terraform plans the module, **Then** the corresponding Helm release omits `repository` and `version`.
2. **Given** an Istio component chart value is a normal chart name, **When** Terraform plans the module, **Then** the corresponding Helm release keeps existing repository and version fallback behavior.
3. **Given** multiple ingress gateways use different chart sources, **When** Terraform plans the module, **Then** each gateway resolves repository/version behavior from its own chart value.

---

### User Story 2 - Use Direct Chart Archives For Kiali Operator (Priority: P2)

As a platform engineer, I can point the Kiali operator chart at a direct upstream `.tgz` archive URL so standalone and Istio-delegated Kiali deployments can use packaged chart sources consistently.

**Why this priority**: Kiali is optional, but the same direct chart archive behavior applies when Kiali is enabled by the Istio module or used directly.

**Independent Test**: Configure `configs.operator.chart` in `modules/kiali` or `configs.kiali.operator.chart` in `modules/istio` with a direct HTTP(S) `.tgz` URL and verify Terraform validation succeeds without requiring `chart_repository` or `chart_version`.

**Acceptance Scenarios**:

1. **Given** Kiali operator chart is a direct `https://.../*.tgz` URL, **When** Terraform plans the module, **Then** the Helm release omits `repository` and `version`.
2. **Given** Kiali operator chart is the default chart name, **When** Terraform plans the module, **Then** the Helm release keeps existing repository and version behavior.

---

### User Story 3 - Wait For Kiali Custom Resource Creation (Priority: P3)

As a platform engineer, I can rely on the Kiali custom resource apply step waiting for readiness so follow-on operations do not race immediately after the CR is submitted.

**Why this priority**: This improves apply reliability for Kiali deployments but depends on the Kiali CR path already being enabled.

**Independent Test**: Enable the Kiali CR and verify the planned `kubectl_manifest` resource includes `wait = true`.

**Acceptance Scenarios**:

1. **Given** `configs.cr.enabled` is true, **When** the Kiali manifest resource is created, **Then** Terraform waits for the manifest readiness signal.
2. **Given** `configs.cr.enabled` is false, **When** Terraform plans the module, **Then** no Kiali manifest is created and no new behavior is introduced.

### Edge Cases

- Consumers set direct chart archive URLs while also setting repository/version values; repository/version values must not be passed to the Helm provider for direct URLs.
- Consumers leave chart fields at defaults; default repository-backed chart behavior must remain unchanged.
- Chart URLs use unsupported schemes such as `oci://` or local paths; this change is limited to HTTP(S) archive URLs and leaves non-HTTP(S) behavior unchanged.
- Ingress gateway entries must be evaluated independently because each list item may use either a repository-backed chart name or a direct archive URL.
- Kiali CR waiting may increase apply duration when the operator or CRD is unavailable; this is intentional readiness behavior rather than a module failure mode.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `modules/istio` MUST detect HTTP(S) chart archive URLs for `configs.base.chart`, `configs.istiod.chart`, every `configs.gateway.ingress_gateways[*].chart`, and `configs.gateway.api_resources.chart`.
- **FR-002**: When an Istio chart value is detected as a direct HTTP(S) URL, the matching `helm_release` MUST set `repository` and `version` to `null`.
- **FR-003**: When an Istio chart value is not a direct HTTP(S) URL, the matching `helm_release` MUST preserve existing repository/version default and override behavior.
- **FR-004**: `modules/kiali` MUST detect HTTP(S) chart archive URLs for `configs.operator.chart`.
- **FR-005**: When the Kiali operator chart is detected as a direct HTTP(S) URL, the operator `helm_release` MUST set `repository` and `version` to `null`.
- **FR-006**: When the Kiali operator chart is not a direct HTTP(S) URL, the operator `helm_release` MUST preserve existing repository/version behavior.
- **FR-007**: `modules/kiali` MUST set `wait = true` on the Kiali `kubectl_manifest` resource whenever the resource is enabled.
- **FR-008**: The change MUST avoid new required inputs and MUST keep existing default usage compatible.
- **FR-009**: Documentation and examples MUST show direct upstream `.tgz` chart URL paths without using customer-specific names or committing generated Terraform state.

### Compatibility & Delivery Requirements

- **CDR-001**: The spec MUST identify both affected module paths and the example path used to prove direct chart archives.
- **CDR-002**: Delivery MUST include validation evidence from `terraform fmt` and affected module/example `terraform validate` where provider initialization is available.
- **CDR-003**: README or example guidance MUST explain that repository/version are ignored for HTTP(S) chart archive URLs.
- **CDR-004**: The Speckit package MUST include `spec.md`, `plan.md`, and `tasks.md` so the module-change gate can associate the implementation with a feature package.

### Key Entities *(include if feature involves data or structured configuration)*

- **Chart Source**: Existing chart string input that may be either a repository-backed chart name or an HTTP(S) direct `.tgz` archive URL.
- **Chart URL Detection Result**: Internal boolean used by Terraform expressions to decide whether a `helm_release` should pass repository/version.
- **Kiali Manifest Readiness Contract**: The behavior that Kiali CR creation waits for readiness when the manifest resource is enabled.
- **Direct Chart Sources Example**: A module example that demonstrates direct upstream chart archive URLs for Istio, Gateway API resources, Kiali, and the helper chart.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Existing default-based Istio and Kiali module usage validates without requiring any input changes.
- **SC-002**: An example using HTTP(S) `.tgz` chart URLs validates without relying on Helm repository indexes for the direct chart sources.
- **SC-003**: Kiali CR resource configuration includes `wait = true` when the CR is enabled.
- **SC-004**: The Speckit package contains complete spec, plan, task, research, data-model, contract, and quickstart artifacts for the change.
- **SC-005**: Scope review confirms no unrelated module interfaces changed in the same delivery.
