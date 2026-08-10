# Implementation Plan: ExternalSecret full sync mode

**Branch**: `016-external-secret-full-sync` | **Date**: 2026-08-07 | **Spec**: [spec.md](spec.md)

## Summary

Extend `modules/external-secret` with an opt-in `sync_all` mode that extracts every property of the configured remote key into the target Secret through `spec.dataFrom[].extract`, while keeping explicit `spec.data[]` mappings as the default. The two modes are mutually exclusive and enforced at plan time. No secret values enter Terraform in either mode.

## Technical Context

**Terraform Version**: `~> 1.3`
**Provider**: Gavinbunney Kubectl `~> 1.14` (unchanged)
**Target Module Path**: `modules/external-secret`
**Examples / Tests**: `tests/invalid_inputs.tftest.hcl` gains full-sync contract and rejection cases; `examples/basic` and `tests/basic` keep demonstrating the default list-sync path, and the README carries the full-sync example.
**Automation Gates**: terraform fmt/validate/test, terraform-docs, Checkov, pre-commit, TFLint
**Target Platform**: Kubernetes with External Secrets Operator v1 and an existing SecretStore or ClusterSecretStore
**Constraints**: One resource, one remote key, one target Secret, values remain external, modes never combine.
**Scale/Scope**: One variable, one manifest branch, one precondition, tests, README, and this Speckit evidence.

## Constitution Check

- [x] I. The module keeps one responsibility: declarative ExternalSecret creation from an existing store. Full sync is a second rendering of the same resource, not a new boundary.
- [x] II. The interface grows by one boolean with a safe default; it is not a CRD pass-through. Full sync serves a common case the enumerate-every-property interface handled badly.
- [x] III. README, tests, and generated docs are updated in the same change.
- [x] IV. `versions.tf` is unchanged and still explicit; all existing gates apply.
- [x] V. The change is additive and opt-in, not breaking. It does reverse the 014 decision to exclude `dataFrom`, so that reversal is recorded below and surfaced for approval on the pull request.

## Research Decisions

| Decision | Rationale | Alternatives considered |
| --- | --- | --- |
| Add `sync_all` (bool, default `false`) rather than inferring the mode from an empty `mappings` list. | An explicit opt-in makes the broader privilege scope visible in the caller's code and keeps an empty list an error rather than a silent behavior switch. | Implicit switch on `length(mappings) == 0`: a typo that drops the mapping list would silently widen the synced key set. |
| Use `spec.dataFrom[].extract` with the single `remote_key`. | It is the documented ESO v1 mechanism for pulling every property of one remote secret into a Secret. | `dataFrom[].find`: matches many remote secrets by regex or tag and would break the module's one-key boundary. |
| Build `spec` with `merge()` of a common block plus one mode-specific block. | Guarantees exactly one of `data` / `dataFrom` is present, keeps the shared fields written once, and keeps the diff for existing consumers empty. | Two full `kubectl_manifest` resources behind `count`: duplicates the shared spec and changes resource addresses for existing consumers. |
| Enforce mode exclusivity with a `lifecycle.precondition` on the resource. | The rule spans two variables, which a single-variable `validation` block cannot express; the precondition still fails during plan. | Cross-variable checks in `variable "mappings"` cannot reference `var.sync_all`. |
| Relax `mappings` to `default = []` and move the non-empty rule into the precondition. | The list is genuinely optional in full-sync mode; content rules (non-blank, unique keys) stay in variable validation where they belong. | Keeping `mappings` required would force full-sync callers to pass `mappings = []` and still fail the old non-empty validation. |
| Keep `examples/basic` and `tests/basic` on list sync. | The example should teach the least-privilege default; full sync is documented in the README and covered by the contract tests. | Converting the example to full sync would advertise the broader mode as normal usage. |

## Modern Capabilities

| Ability | Classification | Evidence |
| --- | --- | --- |
| `spec.dataFrom[].extract` | supported | ESO documents extracting all properties of one remote secret into the target Secret. |
| `spec.data[]` explicit mappings | supported | Unchanged from 014; remains the module default. |
| Mixed `data` and `dataFrom` in one resource | excluded by this module | ESO permits both, but combining them makes the effective key set of the target Secret non-obvious; this module renders exactly one mode. |

References: [ESO ExternalSecret API](https://external-secrets.io/latest/api/externalsecret/) and [ESO API specification](https://external-secrets.io/latest/api/spec/).

## Supersedes

The 014 research decision "do not expose broad `dataFrom` extraction" is narrowed, not discarded. `dataFrom[].extract` against the single configured `remote_key` is now available behind an explicit opt-in; `dataFrom[].find`, which would search across remote secrets, remains excluded.

## Project Structure

```text
modules/external-secret/
├── main.tf          # merge()-built spec with the mode branch and precondition
├── variables.tf     # new sync_all; mappings default [] and relaxed validation
├── README.md        # full-sync section, example, and regenerated inputs table
└── tests/invalid_inputs.tftest.hcl  # full-sync contract plus both rejection cases

specs/016-external-secret-full-sync/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── contracts/module-interface.md
├── quickstart.md
└── tasks.md
```

**Structure Decision**: No files are added to or removed from the module. `outputs.tf` and `versions.tf` are untouched, and no CI matrix entry changes because no module path is added.

## Proposed Changes

1. Add the `sync_all` variable and relax the `mappings` variable to an optional, content-validated list.
2. Branch the rendered `spec` between `dataFrom[].extract` and `data[]`, and add the exclusivity precondition.
3. Add three test runs: full-sync contract, both-modes rejection, and neither-mode rejection.
4. Document full sync in the README with the least-privilege recommendation and regenerate the inputs table.
5. Run formatting, validation, Terraform tests, terraform-docs, and Checkov before the pull request.

## Complexity Tracking

| Exception | Why Needed | Simpler Alternative Rejected Because |
| --- | --- | --- |
| A mode flag inside one module instead of two modules | Both modes render the same resource with the same store, target, and lifecycle semantics; splitting them would duplicate the whole interface for one differing block. | A separate `external-secret-full-sync` module would fork the README, tests, CI matrix entry, and every future fix. |
| `lifecycle.precondition` instead of variable validation | The rule is cross-variable, which Terraform variable validation cannot express. | Single-variable validation cannot see `var.sync_all`, so the invalid combinations would only surface as a confusing ESO-side result. |
