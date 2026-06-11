# Tasks: Helm-Based Ephemeral Helm Cleanup Module

## Chart Dependency

- [x] Confirm the module depends on the separate Helm repo change tracked by `/Users/juliaaghamyan/Desktop/dasmeta/helm/specs/017-base-cronjob-rbac-config/spec.md`.
- [x] Document local chart path usage until `base-cronjob` version `0.1.39` is published.

## Terraform Module

- [x] Replace Kubernetes provider resources with one `helm_release`.
- [x] Switch required provider from Kubernetes to Helm.
- [x] Generate `base-cronjob` values in `locals.tf`.
- [x] Add chart source inputs: `chart_repository`, `chart_name`, `chart_version`.
- [x] Keep client-facing schedule and namespace pattern inputs.
- [x] Add grouped `image`, `service_account`, and `rbac` inputs.
- [x] Add common CronJob and pod controls.
- [x] Add outputs for Helm release status and generated job name.
- [x] Update README usage and local chart development example.
- [x] Update `examples/basic`.
- [x] Keep shell dry-run test coverage.

## Verification

- [x] Run `terraform fmt -check -recursive`.
- [x] Run `terraform -chdir=modules/ephemeral-cleanup-cronjob validate`.
- [x] Run `terraform -chdir=modules/ephemeral-cleanup-cronjob/examples/basic validate`.
- [x] Run `sh modules/ephemeral-cleanup-cronjob/tests/ephemeral-helm-cleanup-test.sh`.

## Release Follow-Up

- [ ] Publish `base-cronjob` chart version `0.1.39`.
- [ ] Update consumers to use the remote chart after publication, or use local chart path during development.
- [ ] Plan Terraform state migration or replacement for any environment that already applied the direct Kubernetes-resource version.
