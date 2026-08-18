# Feature Specification: Add Official GitHub ARC Runner Scale Sets

**Feature Branch**: `019-github-scale-set`  
**Created**: 2026-08-18  
**Status**: Draft  
**Input**: User description: "Add an opt-in official GitHub Actions Runner
Controller scale-set mode to `modules/github-actions-runner`, retain legacy
behavior, use GitHub-supplied Helm charts, and open a reviewable PR."

## Module Context *(mandatory)*

- **Target Module Path**: `modules/github-actions-runner`
- **Related Files In Scope**: module Terraform files, `README.md`, generic
  examples, tests, and this feature's Speckit package.
- **Upstream Baseline**: GitHub-maintained Actions Runner Controller Helm charts:
  `gha-runner-scale-set-controller` and `gha-runner-scale-set`.
- **Requested Interface Change**: Add an opt-in scale-set configuration with
  GitHub scope URL, scale-set name, minimum and maximum capacity, chart pins,
  and Docker-in-Docker mode. Reuse the existing authentication inputs.
- **Breaking Change / Interface Widening**: The optional new configuration is an
  approved bounded interface widening. Existing legacy mode, input names,
  behavior, and state must remain compatible.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Run Autoscaled Official Runners (Priority: P1)

An infrastructure operator can configure one official GitHub runner scale set
for either a repository or an organization. It retains a baseline of idle
runners and creates ephemeral job runners up to a defined limit as work is
queued.

**Why this priority**: Queue-driven scaling is the primary reason to migrate
new deployments away from manually composed legacy runner resources.

**Independent Test**: A Terraform plan with provider mocks renders only the
official controller and scale-set releases, passes the configured GitHub URL,
runner scale-set name, capacity bounds, and Docker build mode, and does not
render legacy resources.

**Acceptance Scenarios**:

1. **Given** a repository or organization GitHub URL and valid authentication,
   **When** the operator selects the scale-set mode, **Then** the module creates
   the controller and one autoscaled runner scale set.
2. **Given** minimum and maximum capacity values, **When** the scale set is
   installed, **Then** its baseline and upper capacity bounds match the supplied
   values.
3. **Given** Docker-based build jobs, **When** a runner is created, **Then** its
   documented execution mode supports Docker-in-Docker.

---

### User Story 2 - Use Existing GitHub Credentials Safely (Priority: P2)

An operator can authenticate the official scale set using the existing
externally managed Kubernetes Secret, or retain the current sensitive-token
input for backwards-compatible automation, without exposing a credential in
documentation or output.

**Why this priority**: The existing secret-management path must work in remote
Terraform execution without adding a second credentials workflow.

**Independent Test**: Mock-provider plans prove the external Secret name is
passed by reference, token mode uses a sensitive chart value, and missing or
ambiguous authentication is rejected.

**Acceptance Scenarios**:

1. **Given** an existing authentication Secret, **When** the scale-set mode is
   selected, **Then** it references that Secret without managing its value.
2. **Given** a sensitive token and no Secret, **When** the scale-set mode is
   selected, **Then** it creates the official chart's authentication value
   without exposing the token in outputs.
3. **Given** zero or two authentication sources, **When** configuration is
   evaluated, **Then** it fails before installation.

---

### User Story 3 - Preserve Legacy Consumers (Priority: P3)

An existing consumer that does not select the new mode retains the legacy
controller and runner behavior without renaming inputs or manually moving
Terraform state.

**Why this priority**: Current pipelines must continue operating while the
official-chart path is reviewed and adopted.

**Independent Test**: A historical legacy input plan still renders the legacy
chart and Runner resource at its documented effective behavior, while the
module includes a state move for the internal Helm address required by the
conditional implementation.

**Acceptance Scenarios**:

1. **Given** existing legacy inputs and no scale-set selection, **When** the
   module is upgraded, **Then** its legacy controller and runner behavior are
   unchanged.
2. **Given** an existing legacy Helm resource in Terraform state, **When** the
   module is upgraded, **Then** Terraform recognizes its compatible moved
   address instead of replacing the controller.

### Edge Cases

- Scale-set mode must reject a missing or malformed GitHub configuration URL.
- The maximum runner count must not be lower than the minimum count.
- A scale-set name must remain valid for Kubernetes and GitHub workflow use.
- Legacy scoped repository and organization modes remain available only in
  legacy mode; one official scale set has exactly one GitHub configuration URL.
- Selecting scale-set mode must not install the legacy controller or legacy
  Runner custom resources.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The module MUST retain legacy mode as its default and preserve the
  existing legacy input contract.
- **FR-002**: The module MUST provide an explicit opt-in mode that deploys only
  GitHub-maintained official scale-set charts.
- **FR-003**: Scale-set mode MUST accept exactly one non-empty GitHub
  configuration URL for either repository or organization scope.
- **FR-004**: Scale-set mode MUST expose a bounded runner scale-set name and
  minimum and maximum runner counts with validation.
- **FR-005**: Scale-set mode MUST configure the supported Docker-in-Docker
  execution mode for Docker build jobs.
- **FR-006**: Scale-set mode MUST reuse exactly one existing authentication
  source: an external Secret reference or the existing sensitive token input.
- **FR-007**: The module MUST not expose token values through outputs,
  documentation, examples, or tests.
- **FR-008**: Legacy resources MUST not be created in scale-set mode, and
  scale-set resources MUST not be created in legacy mode.
- **FR-009**: Existing legacy Helm state MUST be migrated with a Terraform
  `moved` declaration so a normal legacy upgrade does not replace it.
- **FR-010**: The module MUST expose non-sensitive outputs that identify the
  selected mode and scale-set runner label.
- **FR-011**: Documentation MUST explain that workflows use the runner
  scale-set name in `runs-on`, rather than generic self-hosted labels.
- **FR-012**: Documentation, examples, and tests MUST use only generic or
  DasMeta-safe identifiers.

### Compatibility & Delivery Requirements

- **CDR-001**: Scope is limited to `modules/github-actions-runner`, related
  generic examples/tests/documentation, and `specs/019-github-scale-set/`.
- **CDR-002**: The implementation MUST use the official GitHub ARC charts, not
  direct recreations of the controller internals.
- **CDR-003**: Validation MUST include formatting, initialization, static
  validation, Terraform tests for both modes, and example validation.
- **CDR-004**: The PR MUST include migration guidance but MUST NOT alter any
  live legacy PoC deployment.
- **CDR-005**: The final delivery MUST be pushed as a pull request for review.

### Key Entities

- **Deployment Mode**: The mutually exclusive selection of the preserved legacy
  controller path or the official scale-set path.
- **Scale-Set Configuration**: The bounded official-chart settings for one
  GitHub scope, runner label, queue-driven capacity, and chart versions.
- **Authentication Source**: Either the existing Secret reference or the
  sensitive token input, reused by both modes.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Mock-provider tests pass for legacy mode, external-Secret
  scale-set mode, token scale-set mode, and invalid configuration cases.
- **SC-002**: A generic scale-set example initializes and validates without
  live credentials.
- **SC-003**: Scale-set mode renders no legacy resources and exactly two
  official chart releases.
- **SC-004**: Existing legacy tests continue to pass without consumer input
  changes.
- **SC-005**: README guidance lets an operator migrate a workflow by changing
  one `runs-on` value to the documented scale-set name.
