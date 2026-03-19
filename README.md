# terraform-any-shared

Shared Terraform modules and support artifacts maintained by DasMeta.

## Module Housekeeping

Repository-wide support expectations for maintained modules are tracked in:

- `docs/module-housekeeping/module-baseline.md`
- `docs/module-housekeeping/maintained-modules.md`
- `docs/module-housekeeping/exceptions.md`
- `docs/module-housekeeping/validation-coverage.md`

## Validation Overview

- `checkov`, `tflint`, and `pre-commit` cover all maintained top-level modules
- `tfsec` runs repo-wide
- `terraform-test` is enabled for maintained modules that already provide
  standardized example or test scaffolding

## Support-Only Paths

- `modules/k8s/` is currently treated as a support/asset directory rather than
  a consumer-facing Terraform module
