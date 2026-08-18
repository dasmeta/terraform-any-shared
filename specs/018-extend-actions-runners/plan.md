# Implementation Plan: Extend Legacy GitHub Actions Runners

**Branch**: `018-extend-actions-runners` | **Date**: 2026-08-18 | **Spec**: [spec.md](spec.md)
**Input**: Extend `modules/github-actions-runner` for YAML/Terraform Cloud
consumers, multiple repositories, and organization scope without breaking the
historical single-repository contract.

## Summary

Extend the existing legacy Actions Runner Controller wrapper rather than
migrating it. Preserve the historical Helm release resource, runner manifest
resource address, flat input names, safe defaults, and token behavior while
removing the approved customer-specific repository default. Add a grouped
`runner_scope` object for new multi-repository or organization targeting, an
externally managed authentication Secret option, configurable namespace and
chart version, deterministic multi-target names, and non-sensitive diagnostic
outputs. Make the existing kubeconfig-path input nullable: a supplied path keeps
the old local behavior, while `null` lets the kubectl provider consume Terraform
Cloud `KUBE_*` environment credentials.

## Technical Context

**Terraform/OpenTofu Version**: Terraform `~> 1.3`
**Providers / Upstream Modules**: `hashicorp/helm ~> 2.0`, `gavinbunney/kubectl ~> 1.14`, legacy `actions-runner-controller` Helm chart, `actions.summerwind.dev/v1alpha1` Runner CRD
**Target Module Path**: `modules/github-actions-runner`
**Examples / Tests in Scope**: `modules/github-actions-runner/examples/basic`, `modules/github-actions-runner/tests/runner_modes.tftest.hcl`
**Automation Gates**: `terraform fmt`, `terraform init`, `terraform validate`, `terraform test`, `terraform-docs`, pre-commit, tflint, Checkov, tfsec, module-change gate, and `.github/workflows/terraform-test.yaml` coverage
**Target Platform**: legacy ARC on Kubernetes; Terraform Cloud workspaces with Kubernetes credentials supplied through environment variables
**Constraints**: retain legacy ARC and existing resource addresses where possible; do not commit credentials; preserve existing input names; remove the unsafe customer-specific target default with explicit approval; use generic names in reusable artifacts; do not add an unreleased consumer Setup
**Scale/Scope**: one existing shared module, one executable example, one test suite, its README, explicit compatibility files, validation coverage metadata, and this Speckit package

## Pre-change Assessment

### Current module state

- Installs the unpinned legacy `actions-runner-controller` Helm chart into a
  fixed `actions-runner-system` namespace.
- Creates one persistent repository-scoped `Runner` from `runner.yaml`.
- Requires a personal access token and passes it as a non-sensitive Helm set.
- Declares only the kubectl provider and hardcodes `~/.kube/config`, leaving the
  existing `kubectl_config_path` input unused.
- Has no outputs, input validation, executable example, or dedicated tests.
- Is covered by formatting, lint, and static analysis but intentionally excluded
  from the Terraform Test matrix because it has no standardized example.

### Gaps versus internal standards

- Provider and Terraform compatibility are not explicit.
- The credential input is not marked sensitive and the chart cannot reference
  an externally managed Secret.
- Fixed namespace, local-only provider configuration, and one repository target
  prevent the common YAML/Terraform Cloud use case.
- Resource ordering does not explicitly require the controller before runner
  manifests.
- README examples contain non-generic identifiers and an inline token-shaped
  value.
- Examples/tests/outputs are absent.

### Wrapper preservation

The module remains a narrow wrapper for one coherent responsibility: one legacy
ARC controller plus its persistent runner registrations. It will not expose the
full chart surface, runner pod customization, autoscaling, runner groups, or
modern scale-set inputs. Existing flat inputs remain the compatibility path.
Only the new mutually exclusive target selection is grouped because repository
and organization fields form one unambiguous scope boundary. Every grouped field
will be optional and documented inline in `variables.tf`.

### Source and governance assessment

- This is an extension of an existing wrapper, so provider-maintained cloud
  module collection lookup and scratch-template fallback are not applicable.
- Upstream baseline remains the official Actions Runner Controller legacy chart
  and legacy Runner CRD already wrapped by the module.
- Cross-repository standards come from the explicitly requested
  `terraform-module-developer` skill and `.specify/memory/constitution.md`.
- Speckit evidence is `specs/018-extend-actions-runners/{spec.md,plan.md,tasks.md}`;
  once tasks exist, the module-change gate should pass without exemption.
- Interface widening for multiple repositories and organization scope is
  explicitly requested and approved. The requester also explicitly approved
  removing the customer-specific `repo_name` default after review identified
  that an omitted target can register a runner against the wrong repository.

## Constitution Check

*GATE: Passed before research and re-checked after design.*

- [x] Change stays within one coherent module responsibility and the current repository scope.
- [x] Consumer interface remains opinionated; multiple repositories and one organization are the approved bounded widening.
- [x] `README.md`, a basic example, a dedicated test suite, and validation coverage updates are in scope.
- [x] `versions.tf` and `providers.tf` impacts are explicit; established provider families remain compatible with Terraform `~> 1.3`.
- [x] Existing input names and the historical runner resource address are
  preserved. The reviewed removal of the unsafe repository default is the only
  approved breaking contract change.

## Modern Capabilities Classification

| Net-new ability | Classification | Basis |
|-----------------|----------------|-------|
| Multiple explicit repository targets | `exempted` | Modern ARC scale sets are the supported direction, but the requester selected legacy ARC for an older cluster. The official legacy CRD still defines repository targeting, so the exception is bounded to rendering several existing Runner resources. |
| Organization target | `exempted` | Same bounded legacy exception; the official legacy Runner schema defines mutually exclusive organization and repository fields. |
| Existing Kubernetes Secret authentication | `exempted` | The current legacy chart explicitly supports `authSecret.create=false` plus `authSecret.name`; this is the safest available authentication path without migrating controllers. |
| Environment-provided kubectl credentials | `supported` | Kubectl provider `~> 1.14` supports `KUBE_HOST`, `KUBE_TOKEN`, `KUBE_CLUSTER_CA_CERT_DATA`, `KUBE_CONFIG_PATH`, and `KUBE_LOAD_CONFIG_FILE`. |

Primary platform direction: [GitHub ARC overview](https://docs.github.com/en/actions/concepts/runners/actions-runner-controller). Secondary legacy evidence: [official legacy Runner schema](https://github.com/actions/actions-runner-controller/blob/master/apis/actions.summerwind.net/v1alpha1/runner_types.go) and [legacy chart values](https://github.com/actions/actions-runner-controller/blob/master/charts/actions-runner-controller/values.yaml). Provider evidence: [kubectl provider configuration](https://github.com/gavinbunney/terraform-provider-kubectl/blob/master/kubernetes/provider.go).

## Design

### Interface

- Preserve `runner_name`, `repo_name`, `personal_access_token`, and
  `kubectl_config_path` input names. Make `repo_name` nullable with no default
  target and require it explicitly when `runner_scope` is empty.
- Make `personal_access_token` nullable and sensitive; legacy callers passing a
  value remain valid.
- Add `github_auth_secret_name` as a nullable alternative. Exactly one token or
  Secret name is required.
- Add `runner_scope` with optional `repositories` and `organization` fields.
  Both omitted requires an explicit historical `repo_name`; both populated is
  invalid.
- Add `namespace` defaulting to `actions-runner-system` and `chart_version`
  defaulting to `null`; pin the executable example to the reviewed legacy chart
  version so the documented path is reproducible.
- Expose effective target mode and runner resource names only; never output
  credentials.

### Rendering and state compatibility

- Replace the one fixed template field with a generic `scope`/`target` field.
- Keep `kubectl_manifest.pv_mongo_main` for the historical fallback path so its
  state address remains stable.
- Use a separate `for_each` manifest resource only for new multi-repository or
  organization modes.
- Normalize new resource names to lowercase Kubernetes-compatible values and add
  a short hash over the full runner name, scope, and target, preventing both
  owner/name collisions and truncated runner-prefix collisions.
- Keep `helm_release.test` to preserve its resource address. Add optional chart
  version, namespace reuse, sensitive token handling, and existing-Secret values.
- Add an explicit Helm dependency to every runner manifest.

### Provider behavior

- Move required version declarations into `versions.tf` while retaining actual
  kubectl configuration in `providers.tf`, matching modern repository modules.
- Change the provider from a hardcoded path to the existing variable. The
  historical default remains `~/.kube/config`; a YAML consumer passes `null`,
  allowing the provider's environment defaults from its attached Terraform
  Cloud variable set to take effect.
- Helm remains inherited from the consumer and can use the same Terraform Cloud
  Kubernetes credential environment.
- Retain the historical internal kubectl provider for this release to avoid
  silently breaking consumers that rely on it. Document that this legacy
  pattern prevents module-level `count`, `for_each`, and `depends_on`; removing
  it requires a future major-version migration to caller-supplied providers.

### Verification

- A mock-provider Terraform test asserts legacy token mode, external Secret
  mode, multiple repository documents/names, organization scope, output
  contracts, invalid mixed scope/authentication, rejection of a missing target,
  and collision resistance for truncated runner-name prefixes.
- The basic example uses generic targets and an existing Secret reference.
- Adding the standardized example closes the documented Terraform Test coverage
  exception and adds this module to the matrix.
- README regeneration follows the human-written preamble and preserves the
  terraform-docs block.

## Project Structure

### Documentation (this feature)

```text
specs/018-extend-actions-runners/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/module-interface.md
├── checklists/requirements.md
└── tasks.md
```

### Source Code (repository root)

```text
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
│   ├── 0-setup.tf
│   └── 1-example.tf
└── tests/
    └── runner_modes.tftest.hcl

docs/module-housekeeping/
├── exceptions.md
├── maintained-modules.md
└── validation-coverage.md

.github/workflows/terraform-test.yaml
```

**Structure Decision**: Preserve the module's current root layout and resource
addresses, add focused locals/outputs/version files, use the repository's
numbered basic-example convention, and add a native Terraform test file for
behavioral assertions. Update repository-level coverage files only to close the
module's existing documented exception.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Bounded interface widening | A single shared controller must target several selected repositories or one organization from one YAML Setup. | Repeating module blocks would attempt to install the same controller release repeatedly and would not provide one coherent organization mode. |
| Legacy capability exception | The selected cluster is old and the requester explicitly chose the current legacy controller. | Modern runner scale sets are preferred but change the controller, CRDs, authentication flow, and cluster compatibility beyond this request. |
