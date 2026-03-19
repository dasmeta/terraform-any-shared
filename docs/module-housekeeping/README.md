# Module Housekeeping

This directory records the repository-wide housekeeping baseline for maintained
Terraform modules in `terraform-any-shared`.

## Scope

- classify every top-level directory under `modules/`
- distinguish maintained modules from support-only paths
- record required support artifacts and approved exceptions
- map maintained modules to repository validation coverage
- keep documentation and validation alignment visible without reading module
  internals

## Documents

- `module-baseline.md`: the current support-artifact and naming baseline
- `maintained-modules.md`: the maintained-module inventory and status table
- `exceptions.md`: explicit exceptions and approval-gated conflicts
- `validation-coverage.md`: workflow coverage and validation exclusions

## Review Rule

No module is considered silently supported. Each module must appear in the
inventory with a status of `aligned`, `excepted`, or `follow-up-required`.
