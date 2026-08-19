# Implementation Plan: Add Official GitHub ARC Runner Scale Sets

**Branch**: `019-github-scale-set` | **Date**: 2026-08-18 | **Spec**:
[spec.md](spec.md)
**Input**: Add a GitHub-official autoscaled runner path to the existing shared
GitHub Actions runner module while preserving the working legacy path.

## Summary

Extend `modules/github-actions-runner` with a default-preserving
`deployment_mode` switch. The legacy Actions Runner Controller remains the
default. The opt-in `scale_set` path wraps the official GitHub OCI Helm charts:
one controller release and one runner-scale-set release. The scale-set chart
receives an organization or repository GitHub URL, existing Secret reference or
sensitive token, a stable workflow label, capacity limits, pinned chart
versions, and GitHub's built-in Docker-in-Docker mode. It uses GitHub's queue
listener to make runner capacity decisions rather than rendering legacy HRA
resources.

## Technical Context

**Terraform/OpenTofu Version**: Terraform `~> 1.3`  
**Providers / Upstream Charts**: `hashicorp/helm ~> 2.0`,
`gavinbunney/kubectl ~> 1.14`, official GitHub ARC OCI charts
`gha-runner-scale-set-controller` and `gha-runner-scale-set` `0.14.2`  
**Target Module Path**: `modules/github-actions-runner`  
**Examples / Tests in Scope**: `examples/basic`, new `examples/scale-set`, and
`tests/runner_modes.tftest.hcl`  
**Automation Gates**: `terraform fmt`, `terraform init -backend=false`,
`terraform validate`, `terraform test`, terraform-docs, pre-commit, tflint,
Checkov, tfsec, and the module change gate  
**Target Platform**: Kubernetes with Terraform Cloud-provided credentials or
local kubeconfig credentials; GitHub-hosted ARC OCI registry  
**Constraints**: legacy is the default; no credential values or customer names;
the current live PoC is operationally out of scope; a legacy state move must
avoid controller replacement on upgrade  
**Scale/Scope**: one module, two generic examples, one test suite, README, and
this Speckit package

## Pre-change Assessment

### Current module state

- The module deploys the deprecated legacy ARC Helm chart and `Runner` CRs.
- It already supports external authentication Secrets, Terraform Cloud kubectl
  environment credentials, one organization target, and several repository
  targets in legacy mode.
- It has dedicated mock-provider tests and a generic basic example.
- It cannot use the GitHub-supported scale-set controller or queue-driven
  autoscaling.

### Wrapper preservation and interface decision

- Keep all existing flat inputs and their defaults.
- Add `deployment_mode`, default `legacy`, and one optional `scale_set` object.
  The grouped fields are one cohesive scale-set boundary and every field will
  be optional with an inline variable comment.
- Expose only GitHub scope URL, scale-set label, minimum/maximum capacity, and
  pinned chart versions. Do not forward arbitrary Helm values, pod templates,
  GitHub App fields, node placement, or listener metrics.
- The mode is a bounded approved interface widening; it does not weaken legacy
  defaults. Terraform `moved` blocks relocate the legacy Helm address to a
  conditional address with no replacement for normal legacy upgrades.

### Source and governance assessment

- This is an extension of an existing Helm wrapper, so cloud module collection
  lookup and direct-resource template fallback do not apply.
- The official GitHub ARC charts are the upstream baseline. Their documented
  `githubConfigUrl`, pre-defined `githubConfigSecret`, `minRunners`,
  `maxRunners`, `runnerScaleSetName`, and `containerMode.type=dind` values are
  the selected narrow interface.
- Shared governance is sourced from `.specify/memory/constitution.md`; its
  coherent-boundary, opinionated-interface, documentation/test, explicit
  version, and approval-gate requirements are met by this plan.
- The existing module-change gate passes because this feature includes a
  complete downstream Speckit package.

## Constitution Check

*GATE: Passed before research and re-checked after design.*

- [x] The change stays in one runner-management module and current repository.
- [x] The scale-set object is a narrow, explicitly approved interface widening.
- [x] README, generic examples, and mock-provider tests are in scope.
- [x] Existing Terraform/provider constraints remain explicit; chart version
  defaults are additionally pinned for reproducibility.
- [x] The internal Helm resource-address move is documented and safeguards
  legacy state rather than introducing an unapproved behavior break.

## Modern Capabilities Classification

| Net-new ability | Classification | Evidence and decision |
|---|---|---|
| Official queue-driven runner scale set | `replaced` | GitHub documents runner scale sets as the supported ARC autoscaling path; replace new legacy autoscaling composition with the official chart pair. |
| Existing Secret authentication | `supported` | Official chart values explicitly support a pre-defined Kubernetes Secret with `github_token` or GitHub App keys. |
| Docker build runner mode | `supported` | Official chart values provide `containerMode.type: dind` as an out-of-box configuration. |
| Capacity bounds | `supported` | Official chart values define `minRunners` and `maxRunners`; GitHub calculates target runners from minimum idle capacity plus assigned jobs. |

Primary sources: [GitHub ARC getting started](https://docs.github.com/en/actions/tutorials/use-actions-runner-controller/get-started),
[official scale-set deployment guide](https://docs.github.com/en/actions/how-tos/manage-runners/use-actions-runner-controller/deploy-runner-scale-sets),
and the retrieved official `0.14.2` chart values. The preserved legacy behavior
is not refactored as part of this extend-mode change.

## Design

### Module interface

- Add `deployment_mode` with `legacy` default and `scale_set` alternative.
- Add an optional `scale_set` object:
  - `github_config_url`: a GitHub repository or organization HTTPS URL;
    mandatory only in scale-set mode.
  - `runner_scale_set_name`: the workflow `runs-on` label; deterministic
    generic default.
  - `min_runners` / `max_runners`: defaults of 1 and 3, respectively.
  - `controller_chart_version` / `chart_version`: default `0.14.2` and allow
    a reviewable explicit compatibility pin.
- Reuse existing `github_auth_secret_name` and `personal_access_token` mutual
  exclusion. In scale-set mode, Secret mode sets `githubConfigSecret` to the
  externally managed Secret name; token mode sets the sensitive
  `githubConfigSecret.github_token` value.

### Rendering and state compatibility

- Convert `helm_release.test` to a counted `helm_release.legacy[0]` and add a
  `moved` block from the historical resource address. Preserve the legacy
  release name, values, and `kubectl_manifest.pv_mongo_main[0]` behavior.
- Gate legacy `Runner` manifests to legacy mode only.
- In scale-set mode create exactly `helm_release.arc_scale_set_controller[0]`
  and `helm_release.arc_scale_set[0]`, with the scale set depending on the
  controller.
- Set `containerMode.type=dind`; do not introduce custom pod templates.
- Output the active mode and, in scale-set mode, the runner scale-set label;
  keep legacy target outputs intact.

### Examples, documentation, and tests

- Keep the basic legacy example unchanged except for any regenerated docs.
- Add `examples/scale-set` using generic organization scope, external Secret,
  environment-provided Kubernetes credentials, min 1/max 3, and the pinned
  official chart version.
- Add mock tests for official Secret mode, sensitive-token mode, invalid
  missing URL and invalid bounds, and legacy isolation.
- Explain that official scale-set workflows use
  `runs-on: <runner_scale_set_name>`, not generic `self-hosted` labels; state
  that a single scale set is repository- or organization-scoped and an
  organization URL serves all allowed organization repositories.

## Project Structure

```text
specs/019-github-scale-set/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/module-interface.md
├── checklists/requirements.md
└── tasks.md

modules/github-actions-runner/
├── main.tf
├── locals.tf
├── variables.tf
├── outputs.tf
├── versions.tf
├── providers.tf
├── runner.yaml
├── README.md
├── examples/basic/
├── examples/scale-set/
└── tests/runner_modes.tftest.hcl
```

**Structure Decision**: Preserve the existing module layout and provider
constraints. Use only a new generic example directory because the new path is
independently consumable; no repository automation change is required because
the module is already in the Terraform test matrix.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| Bounded interface widening | Consumers need an official scalable path without a separate module. | A full Helm-values pass-through would create an unsupported interface; a separate module would duplicate authentication/provider behavior. |
| Conditional legacy resource address | Official mode must not install legacy ARC. | Leaving the legacy release unconditional installs two controllers; a moved block avoids replacement for legacy callers. |

## Revised Module-Standard Audit (2026-08-19)

The updated `terraform-module-developer` standard was applied after the initial
implementation. This is still module-impacting continuation work under the
existing `specs/019-github-scale-set/` package; no new feature package is
needed.

### Module surfaces

| Axis | Result | Evidence |
|---|---|---|
| Documentation | Updated in this PR | `README.md` has copy-pasteable legacy and scale-set usage, generated input/output documentation, and now documents local verification. |
| Examples | Pass | `examples/basic` and `examples/scale-set` each use `0-setup.tf` and `1-example.tf`; neither contains tests or assertions. |
| Tests | Pass | `tests/runner_modes.tftest.hcl` is directly discoverable by `terraform test`, independently expresses the scale-set use case, and contains assertions or expected failures in every run. |
| Test execution | Pass locally | Terraform `1.15.4` discovered and passed all 13 native tests. The module `~> 1.3` constraint permits Terraform 1.6+ and is unchanged. |
| Test working files | Pass | `.gitignore` excludes `.terraform/`, state, and lock files; no Terraform working files are tracked. |

### Existing repository baseline gaps (out of this module PR scope)

- CI workflows reference shared actions by `@main` and use
  `continue-on-error: true`, so format, validation, lint, and test signals are
  not currently immutable or PR-blocking. The shared Terraform test action also
  does not declare a Terraform `>= 1.6` version in this repository.
- `commitlint.yaml` and `semantic-release.yaml` both publish releases, which is
  an automation-ownership conflict.
- The current pre-commit configuration relies on remote hook environments and
  does not provide the updated standard's explicit missing-tool guidance.

These are repository-governance follow-ups, not safe incidental changes to a
runner-module feature. This PR records them for review but does not modify
automation, release behavior, or unrelated module paths.

## Review Remediation (2026-08-19)

Tigran's review identified three implementation defects in the official ARC
path. The approved remediation preserves the existing consumer inputs,
defaults, runner label behavior, and legacy mode.

- Derive `controllerServiceAccount.name` with the controller chart's exact
  `trunc 63 | trimSuffix "-"` behavior after appending
  `-gha-rs-controller`. Add a long-name test with the chart-rendered expected
  ServiceAccount name rather than asserting only the module's own formula.
- Set the controller chart's supported `flags.watchSingleNamespace` value to
  the existing `namespace` input. This isolates separate module instances in
  separate namespaces without adding a shared-controller abstraction or a new
  consumer input.
- Relocate the historical Helm state move to a documented `moved.tf`, matching
  repository convention and protecting legacy upgrades from accidental move
  removal.

The review's suggestion to reject legacy-only inputs in scale-set mode is
deferred: it would turn previously accepted configurations into plan failures
and conflicts with the approved compatibility-first scope. Container mode and
the idle baseline remain the established opinionated defaults.

### Review remediation verification

- `terraform fmt -check -recursive .`, `terraform validate`, and `terraform
  test` passed in `modules/github-actions-runner`; the native suite reports 14
  passing runs.
- The scale-set example initialized with `-backend=false` and validated.
- Official controller and scale-set Helm 0.14.2 templates rendered with the
  long-name ServiceAccount `arc-example-runners-with-a-rather-long-name-767f83ef-gha-rs-con`.
  The scale-set RoleBinding subject matches the controller chart's rendered
  ServiceAccount, and the controller renders `--watch-single-namespace`.
- Checkov and tfsec completed with no findings; terraform-docs regenerated the
  README block.
