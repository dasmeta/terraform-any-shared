# Implementation Plan: Shared ExternalSecret module

**Branch**: `014-external-secret-module` | **Date**: 2026-08-06 | **Spec**: [spec.md](spec.md)

## Summary

Add `modules/external-secret`, an opinionated Kubectl-provider wrapper that renders one External Secrets Operator v1 resource. It maps selected properties from one existing provider-side secret into one typed Kubernetes Secret. It never reads, generates, outputs, or stores credential values.

## Technical Context

**Terraform Version**: `~> 1.3`
**Provider**: Gavinbunney Kubectl `~> 1.14`
**Target Module Path**: `modules/external-secret`
**Examples / Tests**: `examples/basic`, `tests/basic`, and `tests/invalid_inputs.tftest.hcl`
**Automation Gates**: terraform fmt/validate/test, terraform-docs, Checkov, pre-commit, TFLint, and workflow matrices
**Target Platform**: Kubernetes with External Secrets Operator v1 and an existing SecretStore or ClusterSecretStore
**Constraints**: One resource, one remote key, values remain external, no operator/IAM/credential ownership.
**Scale/Scope**: One module and its docs, tests, CI registration, and Speckit evidence.

## Constitution Check

- [x] The module owns one coherent responsibility: declarative ExternalSecret creation from an existing store.
- [x] The interface stays opinionated: one key, explicit mappings, one target, and a small lifecycle policy set.
- [x] README, example, tests, docs, and workflow coverage are included.
- [x] `versions.tf` retains explicit Terraform and Kubectl constraints.
- [x] No breaking change or unapproved interface widening is proposed.

## Research Decisions

| Decision | Rationale | Alternatives considered |
| --- | --- | --- |
| Render `external-secrets.io/v1` with `kubectl_manifest`. | ESO documents v1 as supported and the repo already renders custom resources with Kubectl. | The Helm service wrapper cannot offer a typed target Secret through a stable narrow interface. |
| Use explicit data mappings. | It limits retrieval to requested properties and permits differing source/target names. | `dataFrom` imports all properties and is too broad. |
| Use a grouped `target` input and flat `remote_key`/`mappings`. | Target lifecycle attributes have one clear boundary; mapping items remain readable and validated. | A generic CRD object would be a broad pass-through. |
| Default to Periodic/1h/Owner/Retain. | These are ESO documented defaults and preserve ordinary rotation. | CreatedOnce/immutable prevents normal rotation; one-minute refresh creates needless provider load. |

## Modern Capabilities

| Ability | Classification | Evidence |
| --- | --- | --- |
| ExternalSecret v1 | supported | ESO documents `external-secrets.io/v1` as the current API. |
| Typed Secret template | supported | ESO documents `spec.target.template.type`. |
| Explicit property mappings | supported | ESO documents `spec.data[].remoteRef.property`; broad `dataFrom` is intentionally excluded. |
| Periodic rotation | supported | ESO documents `refreshPolicy: Periodic` with duration-based refresh. |

References: [ESO ExternalSecret API](https://external-secrets.io/latest/api/externalsecret/) and [ESO API specification](https://external-secrets.io/latest/api/spec/).

## Provider and Baseline Assessment

No appropriate module exists in the approved AWS, Azure, or Google provider-maintained collections because ExternalSecret is a Kubernetes custom resource. The direct-resource fallback follows the repository's established `kubectl_manifest` pattern. The upstream scratch template was refreshed at `fdc7bd8dd4d1dd5f37e1dddf77c0faf559382c39`; only its file-coverage pattern is used, while local conventions remain authoritative.

## Project Structure

```text
modules/external-secret/
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
├── README.md
├── examples/basic/{1-example.tf,README.md}
└── tests/{basic/{main.tf,README.md},invalid_inputs.tftest.hcl}

specs/014-external-secret-module/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── contracts/module-interface.md
├── quickstart.md
└── tasks.md
```

**Structure Decision**: Follow the current CNPG module convention: requirements in `versions.tf`, no module-level provider configuration, manifest resource in `main.tf`, terraform-docs README blocks, and mock-Kubectl Terraform tests.

## Proposed Changes

1. Add module implementation and strict validation.
2. Add a generic example plus manifest contract and invalid-input tests.
3. Generate docs and register the module in all CI matrices.
4. Update agent context for the new ESO v1 capability.

## Complexity Tracking

| Exception | Why Needed | Simpler Alternative Rejected Because |
| --- | --- | --- |
| Direct custom-resource rendering | No approved provider-maintained ExternalSecret wrapper exists. | The existing Helm service wrapper cannot guarantee typed targets and explicit mapping controls. |
