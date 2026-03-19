<!--
Sync Impact Report
Version change: template -> 1.0.0
Modified principles:
- template principle 1 -> I. Coherent Module Boundaries
- template principle 2 -> II. Opinionated Consumer Interfaces
- template principle 3 -> III. Documentation, Examples, and Tests Stay Aligned
- template principle 4 -> IV. Explicit Versions and Automated Quality Gates
- template principle 5 -> V. Approval-Gated Change Management
Added sections:
- Module Standards
- Delivery Workflow
Removed sections:
- None
Templates requiring updates:
- ✅ .specify/templates/plan-template.md
- ✅ .specify/templates/spec-template.md
- ✅ .specify/templates/tasks-template.md
- ⚠ pending .specify/templates/commands/*.md (directory not present in repository)
Follow-up TODOs:
- TODO(RATIFICATION_DATE): original adoption date is not recoverable from repository history
-->
# terraform-any-shared Constitution

## Core Principles

### I. Coherent Module Boundaries
- Each module MUST own one coherent infrastructure responsibility and stay within
  one privilege boundary.
- Changes MUST stay within the current repository scope. If a request expands
  into unrelated modules, external repositories, or cross-cutting automation that
  is not required by the target module, the scope MUST be renegotiated first.
- New capabilities MUST favor the common 80 percent use case over edge-case
  branching and condition-heavy abstractions.

Rationale: This repository is a shared module catalog. Clear boundaries keep
modules composable, reviewable, and safer to consume across teams.

### II. Opinionated Consumer Interfaces
- Modules MUST remain opinionated wrappers instead of broad pass-through layers.
- Variables MUST expose only the commonly changed inputs, include descriptions,
  and prefer defaults, derived values, and validated value sets over forwarding
  rarely used upstream options.
- When a suitable provider-maintained module or chart exists, repository changes
  MUST wrap or compose it before recreating equivalent behavior directly from
  provider resources, unless the spec or plan records a justified fallback.

Rationale: Narrow interfaces reduce support cost, make examples easier to trust,
and preserve the repository's role as a curated Terraform entry point.

### III. Documentation, Examples, and Tests Stay Aligned
- Any change that affects module behavior, provider usage, inputs, outputs, or
  defaults MUST update the target module's `README.md`, relevant `examples/`,
  and relevant `tests/` in the same change.
- `README.md` files MUST preserve the terraform-docs generated block and include
  enough module-specific context for a consumer to understand purpose,
  prerequisites, and primary usage.
- Terraform-based example tests SHOULD use the `0-setup.tf`, `1-example.tf`,
  and `2-assert.tf` layout because it makes setup, usage, and assertions
  reviewable. Deviations MUST be explained in the plan or spec.

Rationale: Shared modules fail in practice when docs, examples, and verification
drift from the interface that consumers actually receive.

### IV. Explicit Versions and Automated Quality Gates
- Version expectations MUST be explicit in `versions.tf`, `version.tf`, and
  `providers.tf` whenever Terraform, OpenTofu, provider, or module compatibility
  matters.
- Changes that affect formatting, documentation, linting, security posture, or
  release behavior MUST preserve repository automation, including pre-commit,
  terraform-docs, CI linting, security scans, and release workflows.
- Plans and pull requests MUST name the validation commands or workflows needed
  to prove the change is safe for the affected module paths.

Rationale: Shared infrastructure code is durable only when consumers can see the
supported versions and when automation continues to enforce the baseline.

### V. Approval-Gated Change Management
- Breaking changes, interface widening, weakened defaults, and standards
  conflicts MUST be surfaced before implementation and MUST NOT be merged
  without explicit approval.
- A change is interface widening when it turns a module into a broader upstream
  pass-through, exposes low-frequency options without a common-case rationale,
  or removes validation that previously constrained supported usage.
- Migration notes or upgrade guidance MUST be included whenever downstream
  consumers would need to change configuration or expectations.

Rationale: Silent interface drift is the fastest way to erode trust in shared
Terraform modules.

## Module Standards

- When relevant to the request, module work MUST review and update
  `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf` or `version.tf`,
  `providers.tf`, `locals.tf`, `README.md`, `examples/`, `tests/`, and
  repository automation files that validate the target module.
- Terraform identifiers MUST use lowercase snake_case. Filenames SHOULD reflect
  a clear responsibility instead of becoming catch-all containers.
- Variables and outputs MUST include descriptions. Variable blocks SHOULD order
  fields as `type`, `default`, then `description` because that matches the
  repository's prevailing style and keeps reviews consistent.
- Text files MUST end with a trailing newline and stay compatible with the
  repository's pre-commit formatting rules.

## Delivery Workflow

- Every spec, plan, and task list MUST name the target module path, related
  examples or tests in scope, repository automation files in scope, and whether
  the change affects inputs, outputs, defaults, providers, or rendered
  resources.
- The plan's Constitution Check MUST confirm coherent scope, opinionated
  interface preservation, synchronized docs/examples/tests, explicit version or
  provider review, and any approval-gated changes.
- Task lists MUST include documentation, example, and verification work whenever
  module behavior or interface changes. Tests are mandatory for those changes
  and may be omitted only for documentation-only edits.
- Module-level documentation MAY explain module-specific behavior, but shared
  governance rules MUST live in this constitution and in synced `.specify`
  templates rather than being redefined ad hoc in module READMEs.

## Governance

- This constitution is authoritative for repository-wide module development and
  supersedes conflicting guidance in local templates or ad hoc notes.
- Amendments MUST update this file, include a Sync Impact Report at the top,
  propagate required changes to dependent templates or guidance files, and
  record any deferred items as explicit TODOs.
- Versioning policy for this constitution uses semantic versioning:
  MAJOR for removed or redefined principles or governance changes that break the
  previous operating model; MINOR for new principles, sections, or materially
  expanded requirements; PATCH for clarifications and wording-only refinements.
- Compliance review is mandatory for every feature spec, implementation plan,
  task list, and pull request that changes modules or repository automation.
  Reviews MUST call out any exceptions, missing updates, or approval-gated
  changes before implementation or merge.
- If the ratification date is later confirmed, the TODO may be replaced without
  changing governance meaning; until then it remains an explicit repository
  record of unknown provenance.

**Version**: 1.0.0 | **Ratified**: TODO(RATIFICATION_DATE): original adoption date unknown | **Last Amended**: 2026-03-19
