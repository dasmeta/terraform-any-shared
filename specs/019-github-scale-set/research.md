# Research: Official GitHub ARC Runner Scale Sets

## Decision: Use GitHub's stable OCI chart pair at version 0.14.2

Use `gha-runner-scale-set-controller` for the controller and
`gha-runner-scale-set` for one autoscaled runner scope.

**Rationale**: GitHub documents these as the ARC installation and runner-scale
set paths. The controller listens to GitHub job demand and manages ephemeral
runners, avoiding the legacy HRA polling configuration.

**Alternatives considered**:

- Continue using the legacy Summerwind `RunnerDeployment` and
  `HorizontalRunnerAutoscaler`: retained for compatibility only; new deployments
  would retain deprecated controller internals and API polling.
- Write ARC CRDs directly: rejected because the official chart is explicitly
  requested and keeps controller internals out of this module.

## Decision: Reuse the existing Secret or sensitive token contract

The official scale-set chart accepts `githubConfigSecret` either as a Secret
name or as a map containing `github_token`. Reuse the module's mutually
exclusive Secret name / sensitive token inputs.

**Rationale**: It supports current Terraform Cloud secret injection without
copying or reading Secret material and preserves existing callers.

## Decision: Set Docker-in-Docker mode

Render `containerMode.type=dind` for the official scale-set chart.

**Rationale**: Official values describe it as the out-of-box configuration for
Docker-based runner jobs, so a custom runner template is unnecessary for the
common build use case.

## Decision: Explicitly link the scale-set chart to its controller service account

Render `controllerServiceAccount.namespace` and
`controllerServiceAccount.name` from the generated controller Helm release
name.

**Rationale**: An official-chart render confirmed that discovery fails when the
controller has a custom release name. The chart's documented explicit
controller service-account settings avoid relying on discovery and work for
namespace-restricted controllers too.

## Decision: Pin compatible official chart versions in the new path

Default both official chart inputs to `0.14.2`, which was retrieved from the
official OCI registry during planning. Permit explicit override for reviewed
cluster compatibility.

**Rationale**: A reproducible default is safer than an implicit latest chart,
especially for existing clusters. The pin is isolated to the opt-in path and
does not modify legacy chart behavior.

## Decision: Preserve legacy state through a moved resource address

Move `helm_release.test` to `helm_release.legacy[0]` in legacy mode.

**Rationale**: Conditional installation is necessary to prevent legacy ARC from
being deployed with official ARC, while Terraform's `moved` block makes a
normal legacy upgrade state-preserving.
