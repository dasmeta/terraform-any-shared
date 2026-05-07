# Feature Specification: Istio and Gateway API Upgrade Configurability

**Feature Branch**: `004-upgrade-istio-gateway-api`  
**Created**: 2026-04-23  
**Status**: Draft  
**Input**: User description: "in dasmeta/terraform-any-shared module repo for istio sub-module we need to be able to set each cumponent(base/istiod/gateway) custom repository and docker image, also lets upgrade gateway-api and istio components chart versions to latest, and also in gateway-api-crds sub-module we need to upgrade crds to latest version and add more information in its README.md on how to upgrade crds yaml and get/set right the new version/crdsList config fields, in gateway-api-crds seem locals.tf can be removed as we no longer use it"

## Module Context *(mandatory)*

- **Target Module Path**: `modules/istio`, `modules/gateway-api-crds`
- **Related Files In Scope**: `modules/istio/variables.tf`, `modules/istio/main.tf`, `modules/istio/README.md`, `modules/gateway-api-crds/variables.tf`, `modules/gateway-api-crds/main.tf`, `modules/gateway-api-crds/README.md`, `modules/gateway-api-crds/locales.tf`, any affected examples and tests under repository `tests/`
- **Upstream Baseline**: Helm-chart-driven deployment patterns for Istio components and managed Gateway API CRD manifests
- **Requested Interface Change**: Allow separate custom repository/image configuration for Istio base, istiod, and gateway components; update chart/CRD versions to latest stable; improve CRD upgrade guidance and version/crdsList configuration documentation
- **Breaking Change / Interface Widening**: Interface widening (new configurable inputs) is expected and must remain backward-compatible through sensible defaults

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

### User Story 1 - Configure per-component Istio images (Priority: P1)

As a platform engineer, I can set custom image repositories and image names for Istio `base`, `istiod`, and `gateway` independently so I can comply with internal registry and image governance without forking the module.

**Why this priority**: This is the core requested capability and directly unblocks deployments in restricted image environments.

**Independent Test**: Set custom values for all three components in one test configuration and verify the resulting planned resources reflect those values while module apply behavior remains stable.

**Acceptance Scenarios**:

1. **Given** a consumer configuration using only existing defaults, **When** the module is planned, **Then** behavior remains equivalent to current baseline behavior.
2. **Given** a consumer sets custom repository/image for `base`, `istiod`, and `gateway`, **When** the module is planned, **Then** each component uses its own configured values independently.
3. **Given** only one component override is provided, **When** the module is planned, **Then** the overridden component uses the custom value and other components keep defaults.

---

### User Story 2 - Upgrade Istio and Gateway API chart versions (Priority: P2)

As a platform engineer, I can consume up-to-date chart versions for Istio and Gateway API-related components so the module remains current and operationally supported.

**Why this priority**: Version freshness is required for maintenance, security posture, and compatibility with current Kubernetes environments.

**Independent Test**: Run module validation with the upgraded default versions and verify successful planning in repository test scenarios that cover affected modules.

**Acceptance Scenarios**:

1. **Given** the module defaults are updated to latest intended versions, **When** standard test scenarios are planned, **Then** no version-resolution or template-rendering failures occur.
2. **Given** downstream consumers rely on defaults, **When** they update to this module release, **Then** they do not need undocumented migration steps for normal use.

---

### User Story 3 - Upgrade and document Gateway API CRD lifecycle (Priority: P3)

As a platform engineer, I can upgrade Gateway API CRDs using clear module documentation and correct `version`/`crdsList` configuration so CRD updates are predictable and repeatable.

**Why this priority**: The request includes explicit CRD upgrade/documentation improvements and cleanup of unused local definitions.

**Independent Test**: Follow the documented README upgrade steps in a clean environment and verify that configuration values map correctly to expected CRD artifacts.

**Acceptance Scenarios**:

1. **Given** updated CRD version defaults, **When** the CRD module is planned, **Then** the targeted CRD set for that version is selected correctly.
2. **Given** a maintainer following README instructions, **When** they update CRD source YAML and module version metadata, **Then** the process is complete without needing implicit tribal knowledge.
3. **Given** `locales.tf` is unused in current behavior, **When** it is removed, **Then** module behavior and tests remain unchanged except for intentional CRD/version updates.

---

### Edge Cases
- Consumers provide malformed or partial image override input (for example missing repository or image value for an overridden component).
- Latest upstream chart/CRD versions introduce renamed values or deprecated fields that do not match existing module assumptions.
- CRD list for a new version is incomplete or includes outdated entries, causing partial CRD rollout.
- Removal of unused locals unexpectedly affects implicit references in examples/tests.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The `modules/istio` module MUST allow independent configuration of repository and image identity for `base`, `istiod`, and `gateway` components.
- **FR-002**: The new image-configuration inputs MUST be optional and preserve existing behavior when not provided.
- **FR-003**: The module MUST reject or clearly fail configurations that provide incomplete image override values for a targeted component.
- **FR-004**: Default version values for Istio and Gateway API-related charts in `modules/istio` MUST be updated to latest approved stable versions at time of change delivery.
- **FR-005**: `modules/gateway-api-crds` MUST update its default CRD version and CRD list to match the latest approved stable Gateway API CRD release.
- **FR-006**: `modules/gateway-api-crds/README.md` MUST include explicit, step-by-step instructions for upgrading CRD YAML source and synchronizing `version` and `crdsList` configuration.
- **FR-007**: The `modules/gateway-api-crds/locales.tf` file MUST be removed if it is not referenced by current module behavior, and any necessary values MUST be sourced without hidden locals.
- **FR-008**: All affected module documentation, examples, and tests MUST be updated so they reflect final supported inputs and default versions.
- **FR-009**: The change MUST keep scope limited to Istio and Gateway API module behavior/documentation and avoid unrelated module interface changes.

### Compatibility & Delivery Requirements

- **CDR-001**: The spec MUST identify the target module path and every related
  example, test, or automation file in scope.
- **CDR-002**: Delivery MUST include validation evidence from repository-standard Terraform checks and affected module test scenarios.
- **CDR-003**: Release notes and module documentation MUST communicate downstream impact for consumers relying on old chart/CRD defaults.
- **CDR-004**: Any compatibility caveat found during validation MUST be documented with a mitigation or rollback path before release.

### Key Entities *(include if feature involves data or structured configuration)*

- **Istio Component Image Override Set**: Consumer-provided per-component image source definitions used to customize `base`, `istiod`, and `gateway` image origin and identity.
- **Istio Version Baseline**: Module default version set that controls deployed Istio and related Gateway API chart revisions.
- **Gateway API CRD Version Contract**: Configuration describing target CRD release (`version`) and the expected CRD artifact list (`crdsList`) that should be rendered/applied.
- **CRD Upgrade Procedure**: Documented maintainer workflow for updating CRD source YAML and aligning module configuration values.

### Assumptions

- "Latest" means the latest stable release approved by maintainers at implementation time, not preview or release-candidate builds.
- Existing consumers should remain functional without requiring immediate input changes if they rely on current defaults.
- Repository-standard validation and tests are sufficient to demonstrate safe rollout for this scope.
- No additional module outputs are required unless required to preserve existing observability/documentation patterns.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of existing default-based usage examples for affected modules can be planned successfully after the upgrade without adding undocumented configuration.
- **SC-002**: A dedicated test scenario confirms each Istio component (`base`, `istiod`, `gateway`) can be overridden independently and yields expected planned values.
- **SC-003**: Documentation users can complete CRD version upgrade preparation using only README instructions in one pass, without additional maintainer clarification.
- **SC-004**: All required repository checks for changed module paths pass before merge.
- **SC-005**: Scope review confirms no unrelated module interfaces were changed in the same delivery.
