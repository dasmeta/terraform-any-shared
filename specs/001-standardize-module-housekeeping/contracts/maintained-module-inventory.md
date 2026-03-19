# Contract: Maintained Module Inventory

## Purpose

Define the minimum reviewable record for every top-level directory under
`modules/` so maintainers, reviewers, and automation can agree on whether a
directory is a maintained consumer-facing module, an excepted nonstandard case,
or a support-only asset path.

## Contract Fields

Each inventory record MUST include:

- `path`
- `classification`
  one of `maintained`, `excepted`, `support-only`
- `reason`
- `required_artifact_profile`
  expected README, examples, tests, version/provider file, outputs/locals
  expectations
- `validation_expectation`
  which automation or documented exception applies
- `status`
  one of `aligned`, `follow-up-required`, `excepted`

## Contract Rules

- Every top-level `modules/*` directory MUST have exactly one inventory record.
- A `maintained` record MUST identify the support artifacts expected for that
  module.
- An `excepted` or `support-only` record MUST explain why the standard
  maintained-module baseline does not apply.
- Inventory classification MUST be sufficient for a reviewer to determine
  whether the module should appear in workflow coverage.
- Missing fields invalidate the inventory record.

## Review Outcomes

- `aligned`: module matches the documented housekeeping baseline
- `follow-up-required`: module is maintained but still missing required
  artifacts or validation
- `excepted`: divergence is intentional and documented

## Non-Goals

- This contract does not redefine module runtime behavior.
- This contract does not widen module interfaces.
