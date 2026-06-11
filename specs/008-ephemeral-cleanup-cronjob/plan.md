# Implementation Plan: Helm-Based Ephemeral Helm Cleanup Module

## Current Repository Module State

The module repository is `/Users/juliaaghamyan/Desktop/dasmeta/terraform-any-shared`.

The target module path is `modules/ephemeral-cleanup-cronjob`.

The moved module contains:

- cleanup script: `scripts/ephemeral-helm-cleanup.sh`
- Terraform module files that create a Helm release through the Helm provider
- example usage under `examples/basic`
- shell dry-run behavior test under `tests`

## Speckit Evidence

- Active package: `specs/008-ephemeral-cleanup-cronjob/`
- Evidence files: `spec.md`, `plan.md`, `tasks.md`
- Speckit bootstrap status: this repository has root `.specify/` metadata and existing root `specs/` packages.
- Module-change gate compatibility: package is now in the repository root specs directory, matching existing repo convention.

## Wrapper Baseline

Chosen baseline: DasMeta Helm chart `base-cronjob`.

Rationale:

- The requested workload is schedule-driven and maps directly to `base-cronjob`.
- Reusing the shared chart avoids recreating CronJob template logic inside Terraform.
- The Terraform module remains an opinionated wrapper for one cleanup job rather than a broad chart pass-through.

Provider-maintained cloud module collections: not applicable. This module targets Kubernetes Helm release deployment, not AWS/Azure/GCP infrastructure primitives.

## Chart Dependency Plan

The required chart extension is tracked in the separate Helm repository under `/Users/juliaaghamyan/Desktop/dasmeta/helm/specs/017-base-cronjob-rbac-config/spec.md`.

The module depends on `base-cronjob` chart support for:

- optional `jobs[].rbac` values
- `templates/rbac.yaml` rendering Role/RoleBinding or ClusterRole/ClusterRoleBinding
- optional CronJob fields:
  - `successfulJobsHistoryLimit`
  - `failedJobsHistoryLimit`
  - `suspend`
  - `jobBackoffLimit`
  - `ttlSecondsAfterFinished`
- `config.envFrom` flag so ConfigMaps can be mounted as files without env import
- ServiceAccount labels support and valid rendering when labels are absent
- README and `values.yaml` documentation
- chart version bump to `0.1.39`

## Terraform Module Plan

Update the module to:

- replace direct Kubernetes provider resources with `helm_release.this`
- replace Kubernetes provider requirement with Helm provider requirement
- build chart values in `locals.tf`
- expose narrow, common inputs in `variables.tf`
- output Helm release details and rendered values
- update README and example usage
- keep the cleanup script sourced from `modules/ephemeral-cleanup-cronjob/scripts/ephemeral-helm-cleanup.sh`
- keep shell dry-run test coverage in `modules/ephemeral-cleanup-cronjob/tests/ephemeral-helm-cleanup-test.sh`

## Interface Shape

Grouped variables:

- `image`: registry, repository, tag, pull policy
- `service_account`: create, name, labels, annotations
- `rbac`: create, cluster-wide flag, name, rules

Flat variables remain for high-frequency operational controls such as `schedule`, `namespace`, `namespace_name_pattern`, and history limits because these are the primary client-specific knobs.

Escape hatches:

- `extra_job_values`
- `extra_values`

These are intentionally present but secondary. Consumers should prefer first-class module variables for common settings.

## Potential Breaking Changes

- Terraform resource addresses change from `kubernetes_*` resources to `helm_release.this`.
- Existing direct-resource Terraform state will not migrate automatically.
- Chart default version is `0.1.39`, which must be published before remote consumers can use the default module configuration.

## Potential Interface Widening

`extra_job_values` and `extra_values` are escape hatches. They widen the interface slightly, but keep the first-class module API narrow while allowing chart-specific overrides without changing this module for every uncommon value.

## Validation Plan

Run:

```bash
terraform fmt -check -recursive
terraform -chdir=modules/ephemeral-cleanup-cronjob init -backend=false
terraform -chdir=modules/ephemeral-cleanup-cronjob validate
terraform -chdir=modules/ephemeral-cleanup-cronjob/examples/basic init -backend=false
terraform -chdir=modules/ephemeral-cleanup-cronjob/examples/basic validate
sh modules/ephemeral-cleanup-cronjob/tests/ephemeral-helm-cleanup-test.sh
```

Expected:

- Terraform root and example validate.
- Shell dry-run behavior remains covered.

## Governance And Standards

- Terraform version constraint uses DasMeta-style pessimistic range `~> 1.3`.
- Provider version is explicit in `versions.tf`.
- Consumer input names avoid client-specific naming.
- Examples use generic namespaces and patterns.
- Shared CronJob behavior remains in the shared Helm chart rather than being copied into Terraform.

## Open Follow-Up

- Publish `base-cronjob` chart version `0.1.39` to `https://dasmeta.github.io/helm`.
