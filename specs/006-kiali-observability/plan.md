# Implementation Plan: Kiali Observability For Istio

**Branch**: `006-kiali-observability` | **Date**: 2026-05-06 | **Spec**: `specs/006-kiali-observability/spec.md`
**Input**: Feature specification from `specs/006-kiali-observability/spec.md`

## Summary

Add a standalone `modules/kiali` module that installs the Kiali operator through Helm and renders a single Kiali custom resource through `kubectl_manifest`. Keep `modules/istio` as an orchestrator that can optionally call `modules/kiali` through `configs.kiali`.

## Current State

- Starting module path: `modules/kiali`, with `modules/istio` delegation in scope
- Related submodules in scope: existing local `modules/gateway-api-crds`; no changes required.
- Repository automation files in scope: none expected.
- Existing standard files present: `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`, `README.md`, examples.
- Existing gaps or inconsistencies: repository has no standalone Kiali module, and the Istio module has no option to delegate to one.

## Comparison Against Internal Standards

- Module design boundary: Kiali has its own module because it can be reused independently, while Istio can optionally orchestrate it.
- Variable and output alignment: add a standalone grouped `configs` input in `modules/kiali`; add matching optional `configs.kiali` input in `modules/istio`.
- Interface shaping:
  - Grouping boundary: `configs.operator` owns the Helm operator release; `configs.cr` owns the Kiali custom resource; `configs.cr.external_services` owns Prometheus and Grafana integration.
  - Required/optional contract preservation: no existing required input changes; all new fields are optional and disabled by default.
- Optional grouped-attribute mapping:
  - Optional fields include operator name/namespace/chart settings, CR name/namespace, auth strategy, view-only mode, deployment overrides, external service fields, and raw `spec`.
  - Optional omission keeps previous module behavior and avoids forced Prometheus or Grafana overrides.
- Documentation, examples, and tests alignment: add `modules/istio/examples/kiali-observability/` and update `README.md`.
- Version and provider alignment: current Helm and kubectl providers are sufficient.

## New-Module Sourcing Assessment

- Not a new module. This is an extension to existing `modules/istio`.
- Provider collection checked: not applicable; request targets Kubernetes/Helm resources rather than AWS/Azure/GCP provider modules.
- Upstream baseline: official Kiali operator Helm chart and official Kiali CR schema.
- Fallback required: no.

## Speckit Evidence

- Speckit package: `specs/006-kiali-observability/`
- Required files: `spec.md`, `plan.md`, `tasks.md`
- Module-change gate status: should pass after this package is present because it identifies the affected module and contains implementation tasks.

## Proposed File Changes

- Files to create:
  - `specs/006-kiali-observability/spec.md`
  - `specs/006-kiali-observability/plan.md`
  - `specs/006-kiali-observability/tasks.md`
  - `modules/kiali/main.tf`
  - `modules/kiali/variables.tf`
  - `modules/kiali/outputs.tf`
  - `modules/kiali/versions.tf`
  - `modules/kiali/locals.tf`
  - `modules/kiali/README.md`
  - `modules/kiali/examples/basic/0-setup.tf`
  - `modules/kiali/examples/basic/1-example.tf`
  - `modules/istio/examples/kiali-observability/0-setup.tf`
  - `modules/istio/examples/kiali-observability/1-example.tf`
- Files to update:
  - `modules/istio/main.tf`
  - `modules/istio/variables.tf`
  - `modules/istio/outputs.tf`
  - `modules/istio/README.md`
- Files to leave unchanged:
  - repository automation
  - `versions.tf`

## Risks and Approvals

- Potential breaking changes: none; Kiali is disabled by default.
- Conflicts requiring approval: none identified.
- Interface widening: bounded. The raw `spec` overlay is intentionally scoped to the Kiali CR so consumers can use advanced Kiali fields without broadening the common-case interface.
- Fallback sources needed: official Kiali docs for Helm installation, Kiali CR, Prometheus, and Grafana fields.

## Execution Notes

- Recommended order of edits:
  1. Add the Speckit package.
  2. Add standalone Kiali module input shape and render locals.
  3. Add Kiali operator Helm release and Kiali CR manifest in `modules/kiali`.
  4. Add Istio delegation to `modules/kiali`.
  5. Add outputs, examples, and README updates.
  5. Run `terraform fmt -recursive modules/istio specs/006-kiali-observability` and Terraform validation where provider initialization is available.
- Validation after edits:
  - `terraform fmt -recursive modules/istio modules/kiali`
  - `terraform -chdir=modules/kiali init -backend=false`
  - `terraform -chdir=modules/kiali validate`
  - `terraform -chdir=modules/istio init -backend=false`
  - `terraform -chdir=modules/istio validate`
  - example validation if provider downloads are available.

## Official Source Notes

- Kiali recommends installing the `kiali-operator` Helm chart and then creating a Kiali CR.
- Kiali CR uses `apiVersion: kiali.io/v1alpha1` and `kind: Kiali`.
- Kiali requires Prometheus for topology graph, metrics, and health.
- Grafana integration is configured through `spec.external_services.grafana` and requires Istio dashboards in Grafana for links to appear.
