# Implementation Plan: Optional Authentik ingress

**Branch**: `016-authentik-ingress` | **Date**: 2026-08-06 | **Spec**: [spec.md](spec.md)

## Summary

Extend `modules/authentik` with a narrow opt-in ingress object. It renders the
official chart's server ingress values, requires hostname/TLS/issuer settings
when enabled, and leaves DNS ownership external. Existing module consumers keep
their current behavior because the module emits no ingress values until the
typed input is supplied.

## Technical Context

**Terraform Version**: `~> 1.3`
**Provider / Upstream**: `hashicorp/helm ~> 3.0`; official Authentik chart `2026.5.6`
**Target Module Path**: `modules/authentik`
**Examples / Tests in Scope**: `modules/authentik/examples/basic`,
`modules/authentik/tests/basic`, `modules/authentik/tests/invalid_inputs.tftest.hcl`
**Automation Gates**: `terraform fmt`, isolated `terraform init`/`validate`,
`terraform test`, `helm template`, pre-commit, tflint and checkov where installed
**Target Platform**: Kubernetes with an existing ingress controller and
cert-manager ClusterIssuer
**Constraints**: no default exposure; no DNS provider or credential inputs; the
module's external database, existing Secret, release identity and ClusterIP
service values remain enforced.
**Scale/Scope**: one shared Helm-wrapper module with docs, example and tests.

## Pre-change standards assessment

- **Current module state**: an opinionated wrapper around the official
  Authentik chart. It fixes release naming, the external PostgreSQL contract,
  existing Secret use, bundled PostgreSQL disablement and ClusterIP service.
- **Wrapper preservation**: the ingress capability extends the existing chart
  wrapper rather than exposing the chart's complete ingress/route surface. It
  supports one NGINX hostname and TLS certificate, with only additional
  annotations as an extension point.
- **Grouped interface decision**: `ingress` is an unambiguous grouping of the
  optional public-route settings. Every field is optional to preserve the
  existing contract, and every grouped field has an inline end-of-line
  description in `variables.tf`.
- **Provider and layout review**: `versions.tf` already declares Terraform
  `~> 1.3` and Helm `~> 3.0`; the repository convention keeps provider
  requirements there and does not need a `providers.tf` change. Existing
  single-file basic examples/tests are preserved rather than imposing another
  layout.
- **Modern capability classification**: **supported**. The official Authentik
  chart `2026.5.6` supports `server.ingress` values (enabled, annotations,
  hosts, TLS and IngressClass), and Helm provider `~> 3.0` supports the existing
  values-based release interface. No deprecated capability is introduced.
- **Upstream / fallback review**: this is an extension of the existing direct
  official-chart wrapper, not new-module creation; provider-maintained module
  collection or scratch-template selection is therefore not applicable.
- **Governance source**: the constitution repository's
  `terraform-module-developer` skill and its internal standards, Speckit
  workflow and planning checklist govern this change.
- **Speckit gate**: active package `specs/016-authentik-ingress/` contains
  `spec.md`, `plan.md` and `tasks.md`; no emergency or bootstrap exemption is
  used, so the downstream module-change gate is expected to pass.

## Constitution Check

- [x] The ingress is a common chart capability and remains part of the single
      Authentik deployment module responsibility.
- [x] The typed, opt-in ingress object is an opinionated interface; arbitrary
      Helm pass-through remains unnecessary for the common path.
- [x] Module source, README, example and tests are in scope.
- [x] Helm provider and chart versions are unchanged; no provider change is
      required.
- [x] The backward-compatible interface widening was explicitly approved by
      the requester; ingress remains disabled by default.
- [x] The grouped ingress fields are optional, inline documented and preserve
      omission/null compatibility with existing extra Helm values.

## Research Decisions

1. **Chart feature**: Authentik chart `2026.5.6` natively supports
   `server.ingress.enabled`, annotations, `ingressClassName`, hosts and TLS.
   Use these values rather than a separate Kubernetes resource.
2. **TLS**: require a cert-manager ClusterIssuer and TLS Secret whenever
   ingress is enabled. Render the issuer annotation and a force-HTTPS redirect
   annotation as module-owned values.
3. **Controller boundary**: use the cluster-standard NGINX IngressClass. The
   HTTPS redirect annotation is NGINX-specific, so allowing arbitrary
   controllers would not preserve the module's HTTPS-only guarantee.
4. **DNS boundary**: the module does not create DNS. Consumers use the separate
   DasMeta Cloudflare records module after its zone is adopted and credentials
   are supplied through a sensitive TFC variable set.
5. **Compatibility**: `ingress=null` is the default. This preserves existing
   `extra_helm_config.server.ingress` values. A hostname, TLS Secret and issuer
   have no safe universal default and must be supplied for an enabled typed
   ingress.

## Interface Design

`ingress` is an optional object with `enabled`, `hostname`, `tls_secret_name`,
`cluster_issuer` and additional annotations. The module
derives all official-chart ingress values from it. Reserved certificate and
HTTPS redirect annotations win over supplied annotations.

## Project Structure

```text
modules/authentik/
├── main.tf
├── variables.tf
├── README.md
├── examples/basic/main.tf
└── tests/
    ├── basic/main.tf
    └── invalid_inputs.tftest.hcl

specs/016-authentik-ingress/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
└── tasks.md
```

**Structure Decision**: extend the existing Authentik wrapper and chart value
set; do not create a separate ingress module or Cloudflare integration.
