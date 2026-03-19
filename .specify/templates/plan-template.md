# Implementation Plan: [FEATURE]

**Branch**: `[###-feature-name]` | **Date**: [DATE] | **Spec**: [link]
**Input**: Feature specification from `/specs/[###-feature-name]/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

[Describe the target module, the requested capability, and the implementation
approach in terms of Terraform modules, providers, charts, or resources.]

## Technical Context

<!--
  ACTION REQUIRED: Replace the content in this section with the technical details
  for the project. The structure here is presented in advisory capacity to guide
  the iteration process.
-->

**Terraform/OpenTofu Version**: [e.g., Terraform ~> 1.3 or NEEDS CLARIFICATION]  
**Providers / Upstream Modules**: [e.g., helm, kubernetes, kubectl, terraform-aws-modules/*]  
**Target Module Path**: [e.g., modules/istio]  
**Examples / Tests in Scope**: [e.g., examples/basic, tests/basic or N/A]  
**Automation Gates**: [e.g., pre-commit, terraform-docs, tflint, tfsec, checkov, terraform-test]  
**Target Platform**: [e.g., Kubernetes cluster, AWS account, GCP project, multi-cloud]  
**Constraints**: [e.g., preserve wrapper interface, no breaking changes without approval]  
**Scale/Scope**: [e.g., single module, module + related examples/tests, repo automation]

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [ ] Change stays within one coherent module responsibility and the current
      repository scope.
- [ ] Consumer interface remains opinionated; any interface widening is
      explicitly documented and approved.
- [ ] `README.md`, `examples/`, and `tests/` updates are listed for every
      behavior or interface change.
- [ ] `versions.tf` or `version.tf` and `providers.tf` impacts are reviewed and
      made explicit when compatibility changes.
- [ ] Breaking changes, weakened defaults, or standards conflicts are recorded
      with approval status before implementation.

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)
<!--
  ACTION REQUIRED: Replace the placeholder tree below with the concrete module
  layout for this feature. Delete unused entries and expand the chosen
  structure with real paths. The delivered plan must not include placeholder
  labels.
-->

```text
modules/[target-module]/
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf or version.tf
├── providers.tf
├── locals.tf
├── README.md
├── examples/
└── tests/

.github/workflows/
.pre-commit-config.yaml
```

**Structure Decision**: [Document the selected structure and reference the real
directories captured above]

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., interface widening] | [current need] | [why existing wrapper shape is insufficient] |
| [e.g., direct resource fallback] | [specific problem] | [why no suitable upstream module/chart exists] |
