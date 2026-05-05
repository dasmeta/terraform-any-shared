# Feature Specification: Keycloak module production readiness

**Feature Branch**: `[005-keycloak-module-review]`  
**Created**: 2026-05-05  
**Status**: Draft  
**Input**: User description: "Recheck Keycloak module for production readiness, especially observability with Prometheus and caching/cache_stack. Module changes were already implemented and tested in a cluster; run Speckit consistency checks again."

## Module Context *(mandatory)*

- **Target Module Path**: `modules/keycloak`
- **Related Files In Scope**:
  - `modules/keycloak/main.tf`
  - `modules/keycloak/variables.tf`
  - `modules/keycloak/outputs.tf`
  - `modules/keycloak/versions.tf`
  - `modules/keycloak/README.md`
  - `modules/keycloak/examples/basic/0-setup.tf`
  - `modules/keycloak/examples/basic/1-example.tf`
  - `modules/keycloak/tests/basic/*`
- **Upstream Baseline**: `codecentric/keycloakx` Helm chart and Keycloak upstream production guidance.
- **Requested Interface Change**: safer production defaults and a small set of additional inputs for:
  - public URL / reverse-proxy awareness (hostname/proxy)
  - clustered cache behavior (cache stack)
  - observability (metrics scraping integration, event metrics, log controls)
  - basic operational safety knobs (timeouts, queued-request limit, termination grace)
- **Breaking Change / Interface Widening**: None expected; changes remain an opinionated wrapper. `extra_configs` remains the escape hatch for low-frequency upstream options.

## User Scenarios & Testing *(mandatory)*

<!--
  IMPORTANT: User stories should be PRIORITIZED as user journeys ordered by importance.
  Each user story/journey must be INDEPENDENTLY TESTABLE - meaning if you implement just ONE of them,
  you should still have a viable MVP (Minimum Viable Product) that delivers value.

  Assign priorities (P1, P2, P3, etc.) to each story, where P1 is the most critical.
  Think of each story as a standalone slice of functionality that can be:
  - Developed independently
  - Tested independently
  - Deployed independently
  - Demonstrated to users independently
-->

### User Story 1 - Deploy production-aligned Keycloak (Priority: P1)

As a platform engineer, I want to deploy Keycloak with production-aligned defaults so that it works correctly behind a reverse proxy/load balancer and can be run as a multi-replica service.

**Why this priority**: Correct hostname/proxy behavior and clustering safety are foundational; if incorrect, login flows can break or loop.

**Independent Test**: Apply the example configuration to a cluster and confirm login flows and OIDC discovery URLs use the expected public URL, without redirect loops.

**Acceptance Scenarios**:

1. **Given** a Keycloak deployment behind TLS-terminating ingress/LB, **When** a user opens the public URL, **Then** the browser does not enter an HTTP↔HTTPS redirect loop and the UI loads successfully.
2. **Given** OIDC discovery is fetched (`/.well-known/openid-configuration`), **When** URLs are returned by Keycloak, **Then** the `issuer` URL starts with the configured public HTTPS base URL (for example `https://<hostname>`).
3. **Given** the deployment is configured with `replicas >= 2`, **When** one pod is restarted, **Then** at least one Keycloak pod remains Ready and OIDC discovery (`/.well-known/openid-configuration`) continues to return HTTP 200.

---

### User Story 2 - Observe health, failures, and latency (Priority: P2)

As an operator, I want metrics and logs that make authentication failures, token errors, and database connectivity issues visible so I can alert and troubleshoot quickly.

**Why this priority**: Keycloak issues are often first visible as login failures, token exchange errors, increased latency, or DB pool exhaustion; observability reduces MTTR.

**Independent Test**: Confirm health endpoints are available, metrics are scraped, and basic dashboards/alerts can be built from emitted metrics.

**Acceptance Scenarios**:

1. **Given** metrics and health are enabled and scraping is configured (ServiceMonitor via Prometheus Operator, or annotation/static scrape), **When** Prometheus scrapes the target, **Then** the scrape target is UP and metrics can be queried.
2. **Given** event metrics are enabled, **When** login attempts succeed and fail, **Then** event counters increase and a login failure ratio can be derived from the counters.
3. **Given** the database becomes temporarily unreachable, **When** Keycloak attempts requests, **Then** errors are visible via logs and DB pool metrics.

---

### User Story 3 - Safe module consumption and upgrades (Priority: P3)

As a consumer of the shared module, I want the module interface to remain narrow, well-documented, and compatible so that upgrading versions does not require undocumented steps.

**Why this priority**: Shared modules are reused across teams; unsafe or unclear interfaces increase support cost and risk.

**Independent Test**: Review README, examples, and tests; run formatting and validation gates.

**Acceptance Scenarios**:

1. **Given** a consumer using the module, **When** they read the module README and example, **Then** they can configure the common production scenario without hidden parameters.
2. **Given** a consumer needs an uncommon chart option, **When** they use `extra_configs`, **Then** the module still applies and remains the source of truth for core defaults.

---

[Add more user stories as needed, each with an assigned priority]

### Edge Cases

<!--
  ACTION REQUIRED: Replace these examples with Terraform-module-specific edge
  cases for the target module.
-->

- Consumers do not have RBAC to create namespaces (must be able to set `create_namespace=false` and pre-create namespace).
- Prometheus Operator CRDs are absent (ServiceMonitor must be optional/off by default to avoid apply failure).
- Proxy headers are misconfigured at the ingress (module must clearly document required reverse-proxy assumptions).
- Running with a single replica (cluster/distributed cache behavior should remain safe and not require extra tuning).
- Consumers omit `hostname_public_url` but deploy behind TLS termination (module should derive safe defaults).

## Requirements *(mandatory)*

<!--
  ACTION REQUIRED: The content in this section represents placeholders.
  Fill them out with the right functional requirements.
-->

### Functional Requirements

- **FR-001**: Module MUST keep a coherent responsibility: deploy Keycloak via Helm chart with external DB and optional ingress wiring.
- **FR-002**: Module MUST provide safe defaults for reverse proxy and public URL behavior suitable for TLS termination at the edge.
- **FR-003**: Module MUST support multi-replica Keycloak deployments with a supported cache discovery approach and configurable cache stack.
- **FR-004**: Module MUST expose health and metrics toggles suitable for production operations.
- **FR-005**: Module MUST support Prometheus scraping integration without requiring cluster-wide CRDs by default (ServiceMonitor optional).
- **FR-006**: Module MUST provide log controls sufficient to troubleshoot auth failures, token flows, admin events, and DB connectivity issues.
- **FR-007**: Changes that affect inputs/defaults MUST update `README.md`, `examples/`, and `tests/` in the same change.
- **FR-008**: Module MUST keep an escape hatch (`extra_configs`) for upstream chart options not modeled as variables.

### Compatibility & Delivery Requirements

- **CDR-001**: Spec MUST name all module files in scope (`main.tf`, `variables.tf`, `README.md`, examples, tests).
- **CDR-002**: Spec MUST acknowledge upstream Keycloak documentation and the `codecentric/keycloakx` chart as the baseline implementation.
- **CDR-003**: Spec MUST define validation steps (formatting, terraform validate; example plan/apply in a cluster as optional manual verification).
- **CDR-004**: Any interface widening or migration requirement MUST be called out explicitly before merge (approval-gated).

### Key Entities *(include if feature involves data or structured configuration)*

- **KeycloakReleaseConfig**: consumer configuration for hostname/proxy, replicas, database, and ingress.
- **ObservabilityConfig**: metrics, ServiceMonitor config, event metrics, and log settings.
- **CacheConfig**: cache discovery stack and related operational settings.

## Success Criteria *(mandatory)*

<!--
  ACTION REQUIRED: Define measurable success criteria.
  These must be technology-agnostic and measurable.
-->

### Measurable Outcomes

- **SC-001**: Consumers can apply the module with a documented example using only documented inputs (no ad hoc patches required).
- **SC-002**: With TLS termination at ingress/LB, the public URL uses HTTPS and does not redirect-loop under normal browser access.
- **SC-003**: When metrics are enabled and scraping is configured, operators can query metrics and derive login success/failure rate and request latency signals.
- **SC-004**: Repository automation gates for the module path (formatting + terraform-docs + validation) pass without manual intervention.
