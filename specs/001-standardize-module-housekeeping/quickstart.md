# Quickstart: Repository Module Housekeeping

## Goal

Execute repository housekeeping so maintained Terraform modules have consistent
support artifacts, validation coverage, and documented exceptions without
changing module behavior.

## Prerequisites

- Work from branch `001-standardize-module-housekeeping`
- Review:
  - `spec.md`
  - `plan.md`
  - `research.md`
  - `data-model.md`
  - `contracts/maintained-module-inventory.md`
  - `contracts/validation-coverage.md`

## Execution Steps

1. Build the maintained-module inventory
   - classify every top-level `modules/*` directory as `maintained`,
     `excepted`, or `support-only`
   - record the exception for `modules/k8s` unless new evidence reclassifies it

2. Reconcile module support artifacts
   - normalize README expectations
   - standardize example and test directory naming
   - add or document missing support artifacts
   - correct non-behavioral naming drift where safe

3. Reconcile repository validation scope
   - compare the maintained inventory against
     `.github/workflows/checkov.yaml`,
     `.github/workflows/tflint.yaml`,
     `.github/workflows/terraform-test.yaml`,
     `.github/workflows/pre-commit.yaml`, and `tfsec.yaml`
   - expand coverage or document exclusions

4. Verify no behavior change slipped in
   - review diffs for runtime Terraform logic changes
   - confirm edits are limited to documentation, structure, naming, validation,
     and exception tracking

## Validation Commands

Run these after implementation:

```bash
PRE_COMMIT_HOME=/tmp/pre-commit-cache python3 -m pre_commit run --all-files
terraform fmt -check -recursive
git diff -- modules .github/workflows .pre-commit-config.yaml README.md docs/module-housekeeping
```

If `pre-commit` applies generated README updates or end-of-file fixes, rerun the
same command until it completes without modifying files.

## Expected Review Outcome

- Every maintained module is classified as aligned, follow-up-required, or
  excepted
- Validation coverage is explicit for every maintained module
- README/example/test expectations are consistent enough to review quickly
- No runtime behavior or interface changes are present
