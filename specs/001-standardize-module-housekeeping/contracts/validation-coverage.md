# Contract: Validation Coverage Mapping

## Purpose

Define the minimum mapping between maintained modules and repository validation
mechanisms so that supported scope and enforced scope remain auditable.

## Contract Fields

Each coverage record MUST include:

- `module_path`
- `validation_mechanism`
  one of `pre-commit`, `checkov`, `tflint`, `terraform-test`, `tfsec`, or
  documented manual validation
- `coverage_state`
  one of `covered`, `partial`, `excluded`
- `evidence_source`
- `exception_reason`
  required when `coverage_state` is `excluded` or `partial`

## Contract Rules

- Every `maintained` module MUST map to at least one validation record.
- A module is not considered fully covered unless the record shows either
  automated validation or an explicit approved exception.
- `tfsec` repo-wide coverage does not replace the need to document module-level
  linting and test expectations where those are part of the baseline.
- If a workflow matrix covers only a subset of maintained modules, the uncovered
  modules MUST appear as `partial` or `excluded` with rationale.
- A missing coverage record is a contract failure.

## Review Outcomes

- `covered`: the module is validated by the documented automation path
- `partial`: some but not all required validation paths apply
- `excluded`: the module is intentionally outside an automation path and the
  reason is documented

## Non-Goals

- This contract does not prescribe exact workflow implementation details.
- This contract does not claim behavioral correctness beyond the validation
  mechanisms it records.
