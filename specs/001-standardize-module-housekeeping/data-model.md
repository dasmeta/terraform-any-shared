# Data Model: Repository Module Housekeeping

## Entity: Maintained Module

**Purpose**: Represents a consumer-facing Terraform module in this repository
that is expected to satisfy the documented housekeeping baseline.

**Fields**:
- `path`: repository-relative module path
- `classification`: `maintained`, `excepted`, or `support-only`
- `surface_type`: `top-level`, `nested-family-module`, or `asset-directory`
- `readme_status`: `aligned`, `missing-context`, `missing-file`, or `excepted`
- `examples_status`: `aligned`, `missing`, `nonstandard`, or `excepted`
- `tests_status`: `aligned`, `missing`, `nonstandard`, or `excepted`
- `standard_file_status`: summary of file coverage for `main.tf`,
  `variables.tf`, `outputs.tf`, `versions.tf` or `version.tf`,
  `providers.tf` or `provider.tf`, and `locals.tf`
- `validation_status`: `repo-wide`, `matrix-covered`, `manual-only`, or
  `excepted`
- `exception_ref`: link or identifier for a documented exception when present

**Relationships**:
- One `Maintained Module` is evaluated against one `Housekeeping Baseline`
- One `Maintained Module` may have zero or more `Documented Exception` records
- One `Maintained Module` may have one or more `Validation Coverage Record`
  entries

## Entity: Housekeeping Baseline

**Purpose**: Defines the minimum non-behavioral standard that maintained
modules must satisfy.

**Fields**:
- `required_structure`: minimum expected Terraform files and directory layout
- `readme_requirements`: generated docs block plus required narrative context
- `example_requirements`: expected example presence and naming convention
- `test_requirements`: expected test presence or exception handling
- `naming_rules`: preferred file names such as `providers.tf`, `versions.tf`,
  `variables.tf`, and `examples/`
- `exception_policy`: what qualifies as an acceptable exception and where it is
  recorded
- `validation_expectations`: what repository automation or explicit exception is
  required for a maintained module

**Relationships**:
- Applied to many `Maintained Module` records
- Referenced by many `Validation Coverage Record` entries

## Entity: Validation Coverage Record

**Purpose**: Captures how a maintained module is validated by repository
automation or documented review.

**Fields**:
- `module_path`: target module path
- `validation_mechanism`: `pre-commit`, `checkov`, `tflint`, `terraform-test`,
  `tfsec`, or documented manual validation
- `scope_type`: `repo-wide`, `matrix-entry`, or `exception`
- `coverage_state`: `covered`, `partial`, or `excluded`
- `evidence_source`: workflow file, config file, or documentation path
- `notes`: rationale for partial or excluded coverage

**Relationships**:
- Many `Validation Coverage Record` entries may attach to one `Maintained
  Module`
- Each `Validation Coverage Record` references the `Housekeeping Baseline`

## Entity: Documented Exception

**Purpose**: Records an intentional departure from the housekeeping baseline.

**Fields**:
- `target_path`: module path or repository file path
- `exception_type`: `support-only-directory`, `missing-example`, `missing-test`,
  `nonstandard-file-name`, `validation-exclusion`, or `other`
- `reason`: plain-language explanation
- `impact`: what the exception means for consumers or reviewers
- `review_trigger`: condition that should cause the exception to be revisited
- `approval_required`: `yes` or `no`

**Relationships**:
- A `Documented Exception` may be associated with one `Maintained Module`
- A `Documented Exception` may justify one or more `Validation Coverage Record`
  exclusions

## State Transitions

### Maintained Module Lifecycle

- `pending-review` -> `aligned`
  when module support artifacts and validation coverage match the baseline
- `pending-review` -> `excepted`
  when the module legitimately diverges and the exception is documented
- `pending-review` -> `follow-up-required`
  when the module is maintained but not yet aligned and no exception justifies
  the gap
- `follow-up-required` -> `aligned`
  when housekeeping gaps are closed without behavior changes
- `follow-up-required` -> `excepted`
  when a justified exception is recorded instead of full alignment

### Validation Coverage Lifecycle

- `partial` -> `covered`
  when the module is added to the required workflow or repo-wide validation path
- `partial` -> `excluded`
  when a documented exception explains why automated coverage does not apply
- `excluded` -> `covered`
  when the exception is resolved and validation is expanded
