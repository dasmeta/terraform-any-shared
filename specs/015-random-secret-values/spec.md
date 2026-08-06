# Feature Specification: Reusable random secret values module

**Feature Branch**: `015-random-secret-values`  
**Created**: 2026-08-06  
**Status**: Ready for planning  
**Input**: User description: "Add a reusable module that generates sensitive named random values for downstream secret stores without exposing values in repository configuration."

## Module Context

- **Target Module Path**: `modules/random-secret-values`
- **Related Files In Scope**: module Terraform files, README, basic example and tests, module test/quality workflow matrices, and this Spec Kit package.
- **Upstream Baseline**: Terraform Random provider `random_password`; the existing AWS Secret module persists a supplied value but does not generate it.
- **Requested Interface Change**: New module that returns a sensitive map of generated and static values, with optional aliases for consumers that must reuse one generated value under more than one key.
- **Breaking Change / Interface Widening**: None; this is a bounded new module. The existing AWS Secret module and CNPG module remain unchanged.

## User Scenarios & Testing

### User Story 1 - Generate reusable secret values (Priority: P1)

An infrastructure consumer declares named generation policies and receives one sensitive map that can be supplied to an existing secret-store module.

**Why this priority**: It removes manual password seeding while keeping secret material out of repository configuration.

**Independent Test**: Apply a fixture with two generated keys and verify the sensitive result contains each configured key with its configured length.

**Acceptance Scenarios**:

1. **Given** two named generation policies, **When** the module is applied, **Then** it returns one sensitive value for each name.
2. **Given** a configured length and character policy, **When** the module is applied, **Then** the generated value follows that policy.

---

### User Story 2 - Compose application credential payloads (Priority: P2)

A consumer combines generated values, non-secret static metadata, and aliases into one payload for an existing secret-store module.

**Why this priority**: Applications commonly require a generated password to be available under both a database key and an application-specific environment key.

**Independent Test**: Apply a fixture with a static owner and an alias, then verify the expected keys exist and the alias equals its source value.

**Acceptance Scenario**:

1. **Given** a static field and an alias to a generated field, **When** the module is applied, **Then** the result contains the static field and the alias matches the source value.

### Edge Cases

- Empty generated-value input, non-positive lengths, and invalid character minima are rejected before generation.
- Static, generated, and alias keys must not collide.
- An alias must refer to a generated or static source key and aliases cannot form chains or cycles.
- Generated values are never rendered in documentation, non-sensitive outputs, test diagnostics, or configuration files.

## Requirements

### Functional Requirements

- **FR-001**: The module MUST generate one independent random value for every configured generated key.
- **FR-002**: The module MUST return a single sensitive map containing generated values, permitted static values, and aliases.
- **FR-003**: The module MUST allow a consumer to configure length and supported character-policy settings for each generated value.
- **FR-004**: The module MUST support aliases that copy an existing generated or static value without generating a second credential.
- **FR-005**: The module MUST reject invalid generation policies, key collisions, missing alias sources, and alias chains before creating credentials.
- **FR-006**: The module MUST NOT create cloud secret stores, Kubernetes Secrets, databases, applications, or credential outputs that are not marked sensitive.
- **FR-007**: The README, examples, tests, generated documentation, and workflow matrices MUST match the final interface.

### Compatibility & Delivery Requirements

- **CDR-001**: The module MUST remain compatible with Terraform `~> 1.3` and use the supported HashiCorp Random provider.
- **CDR-002**: Consumers can pass the sensitive result directly to the existing AWS Secret module without plaintext YAML values.
- **CDR-003**: Formatting, Terraform tests, terraform-docs, Checkov, and repository CI matrices MUST pass before publication.

### Key Entities

- **Generated value policy**: A named random value and its allowed character policy.
- **Static value**: Non-generated metadata included in the same sensitive result map.
- **Alias**: A destination key that reuses another generated or static result value.
- **Sensitive value map**: The sole secret-bearing output intended for a dedicated secret-store consumer.

## Success Criteria

### Measurable Outcomes

- **SC-001**: A consumer can generate a multi-key credential payload and persist it through the existing AWS Secret module with no plaintext secret values in YAML.
- **SC-002**: The basic fixture proves generated values, static fields, and aliases with zero failed Terraform assertions.
- **SC-003**: The module has no non-sensitive output containing credential material.
- **SC-004**: Module-local formatting, tests, documentation generation, and quality checks complete without failures.
