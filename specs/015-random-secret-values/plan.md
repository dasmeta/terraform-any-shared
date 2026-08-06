# Implementation Plan: Reusable random secret values module

**Branch**: `015-random-secret-values` | **Date**: 2026-08-06 | **Spec**: [spec.md](spec.md)
**Input**: Generate sensitive named random values for downstream secret-store modules.

## Summary

Add `modules/random-secret-values`, a narrow Terraform Random provider wrapper.
It generates named values, merges caller-supplied static metadata, and mirrors
selected existing values under alias keys. It emits one sensitive map only.
The existing AWS Secret module remains responsible for writing that map to AWS
Secrets Manager.

## Technical Context

**Terraform/OpenTofu Version**: Terraform `~> 1.3`  
**Providers / Upstream Modules**: `hashicorp/random ~> 3.6`; no provider-maintained module is appropriate because `random_password` is the canonical primitive.  
**Target Module Path**: `modules/random-secret-values`  
**Examples / Tests in Scope**: `examples/basic`, `tests/basic`, `tests/invalid_inputs.tftest.hcl`  
**Automation Gates**: `terraform fmt`, `terraform test`, `terraform-docs`, Checkov, tflint, pre-commit, workflow matrices  
**Target Platform**: Terraform Cloud consumers and downstream secret-store modules  
**Constraints**: One responsibility; no persistence resources; credentials only in a sensitive output; Terraform state is the lifecycle source for generated values.  
**Scale/Scope**: One new shared module, its docs/tests, and its three workflow matrix entries.

## Constitution Check

- [x] Change stays within one coherent module responsibility and the current repository scope.
- [x] Consumer interface is opinionated: named policies, static values, and single-level aliases only.
- [x] README, example, and tests are included.
- [x] `versions.tf` explicitly records Terraform and Random provider compatibility.
- [x] No breaking change or widening of an existing module; the new module has a documented narrow contract.

## Research

See [research.md](research.md). The module needs generated values to cross one
workspace boundary so the existing AWS Secret module can persist them. Its sole
result map must be sensitive; no individual password outputs are exposed.

## Project Structure

```text
modules/random-secret-values/
├── main.tf
├── locals.tf
├── variables.tf
├── outputs.tf
├── versions.tf
├── README.md
├── examples/basic/
│   ├── 0-setup.tf
│   └── 1-example.tf
└── tests/
    ├── basic/
    │   ├── main.tf
    │   └── 2-assert.tf
    └── invalid_inputs.tftest.hcl

specs/015-random-secret-values/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/module-interface.md
└── tasks.md
```

**Structure Decision**: Use the existing module layout and its numbered
example/test convention. Update Terraform test, pre-commit, tflint, and Checkov
workflow matrices for the new module.

## Complexity Tracking

No constitution violations or approval-gated exceptions.
