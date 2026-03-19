# Phase 0 Research: Repository Module Housekeeping

## Decision 1: Treat top-level `modules/*` as the maintained inventory, with `modules/k8s` excepted

**Decision**: Use all top-level directories under `modules/` as the starting
maintained-module inventory except `modules/k8s`, which should be treated as a
support/asset directory unless later evidence proves it is a consumer-facing
Terraform module.

**Rationale**: Nearly every top-level module directory has a recognizable module
signature centered on `README.md` plus `main.tf`, `variables.tf`, and often
`outputs.tf`, `versions.tf` or `version.tf`, `examples/`, or `tests/`.
`modules/k8s` does not present that shape and currently looks like an asset
container.

**Alternatives considered**:
- Classify every `modules/*` directory as maintained:
  rejected because it would force support/assets into misleading compliance.
- Require a fully standard file set before a directory counts as maintained:
  rejected because it would exclude many real modules that are clearly in use
  but currently incomplete.

## Decision 2: Standardize validation around the maintained inventory, not around the current workflow subset

**Decision**: The housekeeping baseline should define maintained-module support
first, then align validation coverage to that inventory through expanded
workflow scope or documented exceptions.

**Rationale**: `checkov.yaml`, `tflint.yaml`, and `terraform-test.yaml`
currently cover only the same 9-module subset, while `tfsec.yaml` runs repo
wide. That means the repository cannot currently infer support scope from
validation scope. The plan needs an explicit mapping instead of preserving the
manual drift.

**Alternatives considered**:
- Preserve the existing matrix coverage as the supported baseline:
  rejected because it silently excludes many modules that appear maintained.
- Make every workflow repo-wide immediately:
  rejected because some modules may need documented exceptions before they can
  satisfy the full baseline.

## Decision 3: Normalize README expectations around a generated block plus short human context

**Decision**: The documentation baseline should require every maintained module
README to preserve the terraform-docs generated block and include a short,
human-written preamble that explains purpose, prerequisites, and primary usage.

**Rationale**: Current module READMEs usually preserve the generated docs block,
but narrative quality varies significantly. Modules like `qdrant` demonstrate a
better consumer experience than modules that contain only generated tables.

**Alternatives considered**:
- Keep generated docs only:
  rejected because it does not satisfy the constitution's requirement for clear
  module purpose and primary usage.
- Write fully custom READMEs for every module:
  rejected because it would duplicate information already maintained by
  terraform-docs and increase drift risk.

## Decision 4: Normalize structure and naming only when the change is non-behavioral

**Decision**: Standardize non-behavioral naming and layout drift where safe,
including `examples/` over `example/`, `providers.tf` over `provider.tf`,
`versions.tf` over `version.tf`, and correction of obvious housekeeping typos,
but treat any rename that risks downstream breakage as an approval gate.

**Rationale**: The repository shows clear housekeeping drift in file names such
as `varables.tf`, `provider.tf`, `version.tf`, `locales.tf`, and `deploy.tf`.
The constitution and internal standards prefer more consistent naming, but the
feature is explicitly barred from introducing behavior changes.

**Alternatives considered**:
- Leave all naming drift in place and only document it:
  rejected because it preserves the inconsistency that the housekeeping feature
  is meant to address.
- Rename every divergent file unconditionally:
  rejected because some names may be relied on by contributor habits or
  undocumented automation and therefore require explicit approval.

## Decision 5: Standardize examples and tests as minimum support artifacts with documented exceptions

**Decision**: Each maintained module should end up with either standardized
examples/tests or an explicit exception note describing why a support artifact
does not apply yet.

**Rationale**: Example coverage is uneven, tests are rare, and the preferred
`0-setup.tf`, `1-example.tf`, `2-assert.tf` test layout is not consistently
used. A documented exception model is necessary to distinguish intentional
absence from unfinished housekeeping.

**Alternatives considered**:
- Require examples and tests for every module immediately:
  rejected because some modules may need staged follow-up and the current repo
  baseline does not support a clean one-shot rollout.
- Treat examples/tests as optional without documentation:
  rejected because it makes support expectations ambiguous for both consumers
  and reviewers.

## Decision 6: No external provider-module research is needed for this feature

**Decision**: Skip provider-maintained module collection research and upstream
scratch-template comparison for this plan.

**Rationale**: This is an existing-module housekeeping effort. It does not
create new modules, widen interfaces, or introduce new provider-backed
capabilities.

**Alternatives considered**:
- Research provider-maintained module baselines anyway:
  rejected because it would not materially affect a non-behavioral housekeeping
  plan.
