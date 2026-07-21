# Implementation Plan: Upgrade Istio Stack Tooling Versions

**Branch**: `009-upgrade-istio-stack-versions` | **Date**: 2026-07-21 | **Spec**: `specs/009-upgrade-istio-stack-versions/spec.md`
**Input**: Feature specification from `/specs/009-upgrade-istio-stack-versions/spec.md`

## Summary

Bump the default tooling versions across the istio stack modules to current stable releases: Istio `base`/`istiod`/`gateway` `1.29.2 -> 1.30.3`, Gateway API CRDs `v1.5.1 -> v1.6.1` (adding the newly-GA `tcproutes`/`udproutes` standard-channel CRDs), and Kiali operator `2.25.0 -> 2.29.0`. Changes are default-only and backward-compatible; consumers who pin versions are unaffected. The dasmeta `gateway-api` resources chart is intentionally left at `0.1.7` because its templates are unchanged. Verification is done locally by applying the `chart-direct-tgz-sources` example against docker-desktop.

## Technical Context

**Terraform/OpenTofu Version**: Terraform `~> 1.3`  
**Providers / Upstream Modules**: `hashicorp/helm (~> 2.0)`, `gavinbunney/kubectl (~> 1.14)`, Helm-chart-managed Istio/Kiali assets, official Gateway API CRD manifests  
**Target Module Path**: `modules/istio`, `modules/gateway-api-crds`, `modules/kiali`  
**Examples / Tests in Scope**: `modules/istio/examples/chart-direct-tgz-sources`  
**Automation Gates**: `pre-commit` hooks (`terraform_fmt`, `terraform_docs`, file hygiene), repo CI checks for Terraform module changes  
**Target Platform**: Kubernetes clusters where Istio + Gateway API CRDs are installed via Terraform-managed Helm/kubectl resources (verified on docker-desktop `v1.34.3`)  
**Constraints**: Preserve current default behavior aside from the version numbers; no interface or breaking changes; no gratuitous chart-version bumps  
**Scale/Scope**: Three existing modules plus one verification example; no new files except the v1.6.1 CRD manifest

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] Change stays within one coherent module responsibility and the current repository scope.
- [x] Consumer interface remains opinionated; no interface widening (defaults-only change).
- [x] `README.md`, `examples/`, and verification artifacts updates are listed for every behavior change.
- [x] `versions.tf` provider compatibility reviewed — unchanged (no provider version impact).
- [x] Breaking changes / weakened defaults: none introduced.

Post-design re-check: PASS (defaults-only upgrade; no constitution gate violations).

## Project Structure

### Documentation (this feature)

```text
specs/009-upgrade-istio-stack-versions/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── module-interface.md
└── tasks.md
```

### Source Code (repository root)

```text
modules/istio/
├── variables.tf                      # fallback version 1.29.2 -> 1.30.3; kiali operator fallback 2.25.0 -> 2.29.0
└── examples/
    └── chart-direct-tgz-sources/
        └── 1-example.tf              # istio 1.30.3, kiali 2.29.0 (gateway-api stays 0.1.7)

modules/gateway-api-crds/
├── variables.tf                      # version v1.5.1 -> v1.6.1; crdsList + tcproutes/udproutes
└── files/
    ├── v1.5.1-standard-install.yaml  # retained for rollback
    └── v1.6.1-standard-install.yaml  # NEW - official v1.6.1 standard-install manifest

modules/kiali/
└── variables.tf                      # chart_version 2.25.0 -> 2.29.0
```

**Structure Decision**: Keep all work localized to the three existing modules and the local verification example. The only new file is the v1.6.1 CRD manifest; the v1.5.1 manifest is retained to allow rollback.

## Phase 0: Research Plan

1. Confirm the latest stable Istio chart versions for `base`/`istiod`/`gateway` and that the chart archives are published.
2. Confirm the latest stable Gateway API CRD release and the exact standard-channel document set (CRDs + validating admission policy) for the `version`/`crdsList` contract.
3. Confirm the latest stable Kiali operator chart version.
4. Define a local validation approach (docker-desktop) that proves in-place upgrade with no destroys and a working test endpoint.

## Phase 1: Design Outputs

- `research.md`: Version-target decisions, upstream sources, and the v1.6 standard-channel CRD-set change.
- `data-model.md`: The version-baseline and CRD version-contract entities and their validation expectations.
- `contracts/module-interface.md`: Confirmation that the interface is unchanged and enumeration of the default deltas.
- `quickstart.md`: Maintainer execution + local verification flow.

Agent context regeneration is intentionally skipped (not explicitly requested).

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| New `crdsList` entries (`tcproutes`/`udproutes`) | v1.6 standard channel promotes these routes to GA; the manifest now contains their CRDs and the list must cover every document | Keeping the old 8-entry list would leave the two new CRD documents unapplied and drift the module from the shipped manifest |
