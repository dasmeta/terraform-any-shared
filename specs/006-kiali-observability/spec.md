# Feature Specification: Kiali Observability For Istio

**Feature Branch**: `006-kiali-observability`
**Created**: 2026-05-06
**Status**: Draft
**Input**: User description: "Separate Kiali module which deploys Kiali and supports the Kiali kind with Prometheus and Grafana integration; Istio should have an option to call the Kiali module."

## Clarifications

### Session 2026-05-07

- Q: Should Kiali customization be included in the Istio custom chart/image overrides example? → A: Yes, include Kiali in `modules/istio/examples/custom-chart-and-image-overrides`.
- Q: Should Kiali chart/image settings be grouped under `configs.kiali.operator` instead of separate top-level Kiali fields? → A: Yes. Use `configs.kiali.operator` as the single context for Kiali operator chart/image configuration.

## Module Context

- **Target Module Path**: `modules/kiali`
- **Related Files In Scope**: `modules/kiali/*`, `modules/kiali/examples/basic/`, `modules/istio/main.tf`, `modules/istio/variables.tf`, `modules/istio/outputs.tf`, `modules/istio/README.md`, `modules/istio/examples/kiali-observability/`
- **Upstream Baseline**: Kiali operator Helm chart from `https://kiali.org/helm-charts` plus Kiali CR `apiVersion: kiali.io/v1alpha1`, `kind: Kiali`
- **Requested Interface Change**: Add a standalone `modules/kiali` module and add optional `configs.kiali` delegation in `modules/istio`.
- **Breaking Change / Interface Widening**: No breaking change. Bounded interface expansion; advanced Kiali CR fields remain available through an explicit raw `spec` overlay.

## User Scenarios & Testing

### User Story 1 - Deploy Kiali With Istio (Priority: P1)

As a platform engineer, I want a standalone Kiali module to deploy the Kiali operator and a Kiali CR so Kiali can be reused independently of Istio orchestration.

**Why this priority**: Kiali deployment is the core deliverable and must work before telemetry integrations matter.

**Independent Test**: Plan the `kiali-observability` example and confirm it renders `helm_release.kiali_operator` and `kubectl_manifest.kiali`.

**Acceptance Scenarios**:

1. **Given** the standalone Kiali module is used with defaults, **When** Terraform plans the module, **Then** it includes a Kiali operator Helm release.
2. **Given** the standalone Kiali module is used with defaults, **When** Terraform plans the module, **Then** it includes a `Kiali` custom resource in the configured namespace.

### User Story 2 - Connect Kiali To Prometheus (Priority: P2)

As a platform engineer, I want to configure the Prometheus endpoint used by Kiali so service graph and health telemetry can work with non-default Prometheus service names or namespaces.

**Why this priority**: Kiali requires Prometheus for topology, metrics, and health visibility.

**Independent Test**: Configure `configs.kiali.cr.external_services.prometheus.url` and confirm the rendered Kiali CR includes `spec.external_services.prometheus.url`.

**Acceptance Scenarios**:

1. **Given** a custom Prometheus URL, **When** the Kiali CR is rendered, **Then** the URL is present under `spec.external_services.prometheus`.
2. **Given** no Prometheus URL override, **When** the Kiali CR is rendered, **Then** no unnecessary Prometheus override is forced.

### User Story 3 - Connect Kiali To Grafana (Priority: P3)

As a platform engineer, I want to enable Grafana links from Kiali so operators can jump from Kiali topology views to Istio dashboards.

**Why this priority**: Grafana improves troubleshooting, but it depends on Kiali and telemetry being present first.

**Independent Test**: Configure Grafana internal and external URLs and confirm the rendered Kiali CR includes `spec.external_services.grafana`.

**Acceptance Scenarios**:

1. **Given** Grafana integration is enabled, **When** the Kiali CR is rendered, **Then** Grafana URLs and dashboard definitions are present.
2. **Given** Grafana integration is disabled, **When** the Kiali CR is rendered, **Then** Grafana support is not implicitly enabled.

### Edge Cases

- Kiali CRs require the Kiali operator CRD to exist before apply.
- Prometheus is required by Kiali; module consumers may still use the default Kiali assumption when no custom URL is supplied.
- Grafana dashboard links require Istio dashboards to exist in Grafana.
- Clusters without the Kiali operator should not create a Kiali CR unless the caller explicitly disables operator management and handles the CRD separately.

## Requirements

### Functional Requirements

- **FR-001**: The module MUST keep Kiali disabled by default to preserve existing Istio deployments.
- **FR-002**: The standalone Kiali module MUST install the Kiali operator through Helm when `configs.enabled` and `configs.operator.enabled` are true.
- **FR-003**: The standalone Kiali module MUST support rendering a `kiali.io/v1alpha1` `Kiali` custom resource when `configs.cr.enabled` is true.
- **FR-004**: The module MUST support Prometheus URL and common Prometheus settings in the Kiali CR.
- **FR-005**: The module MUST support Grafana enablement, URLs, datasource UID, dashboards, and common auth settings in the Kiali CR.
- **FR-006**: The module MUST expose a raw Kiali CR `spec` overlay for advanced fields without converting the wrapper into a full pass-through interface.
- **FR-007**: The Istio module MUST support optional delegation to `modules/kiali` through `configs.kiali`.
- **FR-008**: README and examples MUST document both standalone and Istio-delegated Kiali configuration paths.
- **FR-009**: The `modules/istio/examples/custom-chart-and-image-overrides` example MUST include `configs.kiali` customization to demonstrate Kiali usage alongside chart/image override workflows.
- **FR-010**: Kiali operator chart and image configuration MUST be grouped under `configs.kiali.operator` (including chart source/version and operator image settings) instead of separate top-level Kiali chart/image fields.

### Compatibility & Delivery Requirements

- **CDR-001**: Existing Istio behavior must remain unchanged when Kiali is omitted.
- **CDR-002**: No provider version change is required unless validation proves the current `helm` and `kubectl` providers are insufficient.
- **CDR-003**: Validation must include Terraform formatting and module/example validation where provider initialization is available.
- **CDR-004**: Because interface grouping changes can affect existing consumers, migration notes MUST document how previous top-level Kiali chart/image fields map to `configs.kiali.operator`.

### Key Entities

- **Kiali Operator Release**: Helm release that installs the Kiali operator and CRDs.
- **Kiali CR**: Kubernetes custom resource watched by the Kiali operator to deploy the Kiali server.
- **Kiali External Services**: Prometheus and Grafana configuration used by the Kiali server.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Consumers can enable Kiali with a documented module example.
- **SC-001a**: Consumers can enable Kiali from the `custom-chart-and-image-overrides` example without adding a separate example module.
- **SC-002**: Consumers can configure Prometheus and Grafana integrations without writing raw YAML for the common case.
- **SC-003**: Existing module consumers see no plan changes when `configs.kiali` is omitted.
- **SC-004**: Terraform formatting succeeds for all changed Terraform files.
