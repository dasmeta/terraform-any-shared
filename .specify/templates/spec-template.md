# Feature Specification: [FEATURE NAME]

**Feature Branch**: `[###-feature-name]`  
**Created**: [DATE]  
**Status**: Draft  
**Input**: User description: "$ARGUMENTS"

## Module Context *(mandatory)*

- **Target Module Path**: [e.g., `modules/istio`]
- **Related Files In Scope**: [e.g., `README.md`, `examples/basic`, `tests/basic`,
  `.github/workflows/terraform-test.yaml`]
- **Upstream Baseline**: [provider-maintained module, Helm chart, direct
  resources, or N/A]
- **Requested Interface Change**: [inputs, outputs, defaults, provider
  versions, rendered resources]
- **Breaking Change / Interface Widening**: [None, proposed with approval
  required, or NEEDS CLARIFICATION]

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

### User Story 1 - [Brief Title] (Priority: P1)

[Describe this user journey in plain language]

**Why this priority**: [Explain the value and why it has this priority level]

**Independent Test**: [Describe how this can be tested independently - e.g., "Can be fully tested by [specific action] and delivers [specific value]"]

**Acceptance Scenarios**:

1. **Given** [initial state], **When** [action], **Then** [expected outcome]
2. **Given** [initial state], **When** [action], **Then** [expected outcome]

---

### User Story 2 - [Brief Title] (Priority: P2)

[Describe this user journey in plain language]

**Why this priority**: [Explain the value and why it has this priority level]

**Independent Test**: [Describe how this can be tested independently]

**Acceptance Scenarios**:

1. **Given** [initial state], **When** [action], **Then** [expected outcome]

---

### User Story 3 - [Brief Title] (Priority: P3)

[Describe this user journey in plain language]

**Why this priority**: [Explain the value and why it has this priority level]

**Independent Test**: [Describe how this can be tested independently]

**Acceptance Scenarios**:

1. **Given** [initial state], **When** [action], **Then** [expected outcome]

---

[Add more user stories as needed, each with an assigned priority]

### Edge Cases

<!--
  ACTION REQUIRED: Replace these examples with Terraform-module-specific edge
  cases for the target module.
-->

- What happens when required providers or version constraints differ from the
  current module baseline?
- How does the module behave when consumers omit optional config that the
  module intends to default or derive?
- What happens if a requested feature would require exposing low-frequency
  upstream options or weaken existing validation?

## Requirements *(mandatory)*

<!--
  ACTION REQUIRED: The content in this section represents placeholders.
  Fill them out with the right functional requirements.
-->

### Functional Requirements

- **FR-001**: Target module MUST preserve one coherent infrastructure
  responsibility.
- **FR-002**: Target module MUST expose only the supported consumer inputs and
  defaults required for the common use case.
- **FR-003**: Any behavior, interface, provider, or version change MUST update
  the module `README.md`, relevant `examples/`, and relevant `tests/`.
- **FR-004**: Version and provider expectations MUST remain explicit in the
  module files that define compatibility.
- **FR-005**: Breaking changes, standards conflicts, or interface widening MUST
  be documented with approval status before implementation.

*Example of marking unclear requirements:*

- **FR-006**: Module MUST support provider or chart version
  [NEEDS CLARIFICATION: version or compatibility target not specified]
- **FR-007**: Module MUST expose upstream option
  [NEEDS CLARIFICATION: common-case need and approval for interface widening not specified]

### Compatibility & Delivery Requirements

- **CDR-001**: The spec MUST identify the target module path and every related
  example, test, or automation file in scope.
- **CDR-002**: The spec MUST state whether an upstream module or chart was
  considered before direct resource-based implementation.
- **CDR-003**: The spec MUST describe expected validation, including module
  tests and repository automation gates that prove the change is safe.
- **CDR-004**: If migration guidance is required, the spec MUST describe the
  downstream impact in plain language.

### Key Entities *(include if feature involves data or structured configuration)*

- **[Input Object or Resource Group]**: [What it represents, key attributes
  without implementation detail]
- **[Output Contract or Helm Values Set]**: [What it represents, relationships
  to module behavior]

## Success Criteria *(mandatory)*

<!--
  ACTION REQUIRED: Define measurable success criteria.
  These must be technology-agnostic and measurable.
-->

### Measurable Outcomes

- **SC-001**: Consumers can apply the updated module using the documented
  example without undocumented manual steps.
- **SC-002**: Module validation passes for the affected paths using the
  repository's required automation or documented equivalent checks.
- **SC-003**: README, examples, and tests match the final supported interface.
- **SC-004**: Any breaking change or interface widening is either approved with
  migration guidance or avoided.
