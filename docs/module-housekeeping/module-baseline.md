# Module Housekeeping Baseline

## Required Baseline

Maintained top-level modules in `modules/` are expected to provide:

| Artifact | Expectation |
|----------|-------------|
| README | Human-written purpose and usage context above the terraform-docs block |
| Examples | `examples/` with a consistent scenario layout, or a documented exception |
| Tests | `tests/` or example-based verification, or a documented exception |
| Version/provider files | Prefer `versions.tf` and `providers.tf`; older or divergent file names require an explicit decision |
| Validation mapping | Clear workflow coverage or a documented exclusion |
| Naming | Prefer repository-standard names and directory shapes when safe to normalize |

## Preferred Naming Rules

| Current Pattern | Preferred Pattern | Notes |
|-----------------|-------------------|-------|
| `provider.tf` | `providers.tf` | Safe non-behavioral rename unless an approval gate is recorded |
| `version.tf` | `versions.tf` | Safe non-behavioral rename unless an approval gate is recorded |
| `example/` | `examples/basic/` | Standardize singular example paths where safe |
| Misspelled support files | corrected standard file name | Normalize typos only when Terraform behavior is unchanged |

## Exception Policy

- A module may be `excepted` when an artifact is intentionally absent, a
  nonstandard file name is retained for compatibility, or a workflow does not
  yet apply.
- Approval-gated exceptions must be recorded in `exceptions.md` before any
  structural rename that could surprise consumers or maintainers.
- Support-only directories are recorded separately and do not inherit the
  maintained-module baseline.

## Validation Expectations

- `checkov`, `tflint`, and `pre-commit` are the primary repo-wide maintenance
  gates for maintained modules.
- `tfsec` runs repo-wide and complements module-scoped validation.
- `terraform-test` is expected where a module has standardized example or test
  scaffolding; exclusions must be recorded explicitly.
