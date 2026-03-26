# Contract: Keycloak Validation Scope

## Purpose

Define the minimum validation and support-artifact scope required before
`modules/keycloak` is treated as a maintained module in this repository.

## Contract Fields

Each validation record for the new module MUST identify:

- `module_path`
- `artifact_type`
  one of `README`, `example`, `test`, `workflow-matrix`, `terraform-format`,
  `terraform-validate`, or `pre-commit`
- `status`
  one of `required`, `covered`, `partial`, or `excluded`
- `evidence_source`
- `notes`

## Contract Rules

- `modules/keycloak/README.md` MUST include human-written module context plus
  the terraform-docs generated block.
- `modules/keycloak/examples/basic/` MUST provide one runnable supported usage
  path for the curated interface.
- `modules/keycloak/tests/basic/` MUST provide one Terraform validation path
  that exercises the supported interface without relying on hidden inputs.
- `modules/keycloak` MUST be added to the maintained-module matrices in
  `.github/workflows/checkov.yaml` and `.github/workflows/tflint.yaml`.
- `modules/keycloak` MUST be added to `.github/workflows/terraform-test.yaml`
  unless implementation evidence proves the repository’s test harness cannot
  support the module yet, in which case the exclusion must be documented before
  merge.
- Formatting and generated docs updates MUST be compatible with the current
  `.pre-commit-config.yaml` baseline.

## Review Outcomes

- `covered`: README/example/test artifacts exist and workflow coverage is
  aligned
- `partial`: some validation exists but a required artifact or matrix entry is
  still missing
- `excluded`: a documented, reviewed exception explains why a required path is
  absent

## Non-Goals

- This contract does not require live cluster integration testing.
- This contract does not replace the module interface contract.
