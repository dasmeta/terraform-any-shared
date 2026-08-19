# Feature Specification: ExternalSecret full sync mode

**Feature Branch**: `016-external-secret-full-sync`
**Created**: 2026-08-07
**Status**: Ready for implementation

## Module Context

- **Target Module Path**: `modules/external-secret`
- **Related Files In Scope**: `main.tf`, `variables.tf`, `tests/invalid_inputs.tftest.hcl`, module `README.md`, and this Speckit package.
- **Upstream Baseline**: Unchanged. The module keeps rendering External Secrets Operator `external-secrets.io/v1` resources through the repository's Kubectl provider convention.
- **Requested Interface Change**: Add one optional `sync_all` boolean that switches the module from the explicit `spec.data[]` mapping list to `spec.dataFrom[].extract` full extraction of one remote key.
- **Breaking Change / Interface Widening**: Additive and opt-in. `sync_all` defaults to `false`, and `mappings` gains a `[]` default while its non-empty requirement moves from variable validation to a resource precondition. Existing consumers that pass `mappings` keep identical rendered output.

## User Scenarios & Testing

### User Story 1 - Sync every property of a remote secret (Priority: P1)

An infrastructure consumer needs the whole contents of one provider-side secret in a Kubernetes Secret because the property set is owned outside Terraform and changes without module edits.

**Why this priority**: Without this, consumers must enumerate every property and re-apply Terraform each time the provider-side secret gains a key, which is the main reason teams bypass the module.

**Independent Test**: Render the module with `sync_all = true` and no mappings, then verify the manifest carries `spec.dataFrom[0].extract.key` for the remote key and carries no `spec.data`.

**Acceptance Scenarios**:

1. **Given** an existing SecretStore and remote key, **When** `sync_all = true` and `mappings` is empty, **Then** the ExternalSecret extracts every property of that remote key into the target Secret.
2. **Given** the same configuration, **When** the manifest is rendered, **Then** no `spec.data` block is emitted, so the two sync modes never appear together.

### User Story 2 - Preserve explicit list sync as the default (Priority: P1)

An existing consumer keeps least-privilege mappings and expects no change from upgrading the module.

**Why this priority**: Full sync is broader than least privilege, so the safer mode must remain the default and must stay byte-identical for current callers.

**Independent Test**: Render the pre-existing mapping fixtures unchanged and confirm store, remote key, mappings, target name, type, and lifecycle policies still match.

**Acceptance Scenarios**:

1. **Given** a configuration with `mappings` and no `sync_all`, **When** the manifest is rendered, **Then** `spec.data[]` is emitted exactly as before and no `spec.dataFrom` appears.

### User Story 3 - Reject ambiguous mode combinations (Priority: P2)

A consumer misconfigures the module by setting both modes, or neither.

**Why this priority**: A silently ignored input in secret distribution produces a Secret with the wrong key set, which fails at workload start rather than at plan time.

**Independent Test**: Plan `sync_all = true` with a non-empty `mappings`, and plan `sync_all = false` with an empty `mappings`; both must fail.

**Acceptance Scenarios**:

1. **Given** `sync_all = true` and one or more mappings, **When** Terraform plans, **Then** the plan fails with a message naming both valid modes.
2. **Given** `sync_all = false` and no mappings, **When** Terraform plans, **Then** the plan fails with the same guidance.

### Edge Cases

- Mode selection is validated at plan time, not at apply time, so a wrong mode never reaches the cluster.
- Mapping content rules (non-blank keys and properties, unique `secret_key`) still apply to whatever mappings are supplied.
- Full sync copies the property names the provider owns; the module cannot rename keys in this mode.
- Secret values, remote content, and provider credentials remain absent from inputs, outputs, examples, tests, and documentation in both modes.

## Requirements

### Functional Requirements

- **FR-001**: The module MUST accept an optional `sync_all` boolean that defaults to `false`.
- **FR-002**: When `sync_all` is `true`, the module MUST render `spec.dataFrom[].extract.key` for the single `remote_key` and MUST NOT render `spec.data`.
- **FR-003**: When `sync_all` is `false`, the module MUST render `spec.data[]` from `mappings` exactly as before and MUST NOT render `spec.dataFrom`.
- **FR-004**: The module MUST fail at plan time when `sync_all` is `true` and `mappings` is non-empty.
- **FR-005**: The module MUST fail at plan time when `sync_all` is `false` and `mappings` is empty.
- **FR-006**: The module MUST keep the store reference, remote key, target template type, refresh policy, and lifecycle policy behavior identical across both modes.
- **FR-007**: The module MUST NOT accept, output, or log secret values in either mode.
- **FR-008**: The README MUST document full sync, state that the modes are mutually exclusive, and recommend explicit `mappings` as the least-privilege default.

### Compatibility & Delivery Requirements

- **CDR-001**: Existing configurations that set `mappings` MUST plan without changes and MUST produce an unchanged manifest.
- **CDR-002**: The module MUST remain compatible with Terraform `~> 1.3` and the existing Gavinbunney Kubectl provider constraint; no new provider or version requirement is introduced.
- **CDR-003**: `spec.dataFrom[].extract` MUST be used only as documented for `external-secrets.io/v1`.
- **CDR-004**: Formatting, Terraform tests, terraform-docs, TFLint, Checkov, and the existing CI matrices MUST pass. No workflow matrix change is required because no module path is added.

### Key Entities

- **Sync mode**: The mutually exclusive choice between explicit list sync (`spec.data[]`) and full sync (`spec.dataFrom[].extract`).
- **Mapping**: Unchanged. One Kubernetes `secret_key` paired with one `remote_property` under the single remote key; used only in list sync.

## Success Criteria

- **SC-001**: A consumer can sync every property of one remote secret with one boolean and no mapping list.
- **SC-002**: Every pre-existing test for list sync passes unchanged, proving the default path is untouched.
- **SC-003**: Both invalid mode combinations fail at plan time with an actionable message, verified by tests.
- **SC-004**: Module-local checks complete with zero failed Terraform tests and zero new Checkov findings.
- **SC-005**: The README documents both modes and states the least-privilege recommendation.
