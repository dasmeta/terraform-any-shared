# Implementation Plan: Shared Authentik deployment module

**Branch**: `011-shared-authentik` | **Date**: 2026-07-29 | **Spec**: [spec.md](spec.md)
**Input**: DMVP-10317 refined requirements.

## Summary

Create `modules/authentik`, a narrow Helm wrapper for the official Authentik
chart. It consumes a pre-existing namespace, PostgreSQL database/user/grants,
and configuration Secret. It exposes only chart version, release identity,
external database metadata, and deterministic internal endpoint outputs.

## Technical Context

**Terraform Version**: `~> 1.3`
**Provider**: `hashicorp/helm ~> 3.0`
**Upstream**: official `authentik` chart, repository
`https://charts.goauthentik.io`, default chart version `2026.5.6`
**Target Module Path**: `modules/authentik`
**Examples / Tests**: `modules/authentik/examples/basic`,
`modules/authentik/tests/basic`
**Target Platform**: caller-configured Kubernetes cluster with Helm access
**External Prerequisites**: namespace, PostgreSQL database/user/grants, and a
Kubernetes Secret in that namespace with `AUTHENTIK_SECRET_KEY` and
`AUTHENTIK_POSTGRESQL__PASSWORD`
**Automation Gates**: `terraform fmt`, isolated `terraform init -backend=false`
and `terraform validate`, deterministic `helm template`, repository static
analysis and pre-commit when available.

## Constitution Check

- [x] Single responsibility: deploy Authentik; no cluster foundation,
  ingress, database, Secret, or tenant/application lifecycle ownership.
- [x] Narrow interface: no arbitrary Helm-value escape hatch, credentials,
  SMTP, blueprints, outposts, or ingress configuration in v1.
- [x] Required module source, documentation, example, test, and CI matrix
  coverage are planned together.
- [x] No breaking change: new module only.
- [x] Shared governance comes from `terraform-module-developer`; repository
  conventions keep required providers in each module's `versions.tf`.

## Research Decisions

1. **Upstream baseline**: use the official Authentik Helm chart. The approved
   cloud provider module collections do not provide an Authentik module, so a
   direct `helm_release` wrapper is the bounded fallback.
2. **Current chart capability**: version `2026.5.6` supports
   `authentik.existingSecret.secretName`; its server and worker load that Secret
   with `envFrom`. The Secret keys follow Authentik configuration environment
   variable names.
3. **Database lifecycle**: set `postgresql.enabled = false`; pass host, port,
   name, and user as non-secret `AUTHENTIK_POSTGRESQL__*` environment variables.
   The existing configuration Secret carries the app key and database password,
   so Terraform never receives a secret value.
4. **Service identity**: set `fullnameOverride` to the validated release name.
   The chart creates its server Service as `<release-name>-server`, allowing a
   separately managed ingress to consume a stable output without the module
   owning DNS or routes.
5. **Current architecture**: current Authentik releases removed Redis. No Redis
   resource, chart setting, or dependency belongs in the module.
6. **Modern capability classification**:
   - `helm_release` with Helm provider 3.x: **supported**.
   - Authentik existing Secret reference: **supported** by the official chart.
   - External PostgreSQL with bundled PostgreSQL disabled: **supported** by the
     official chart.
   - Redis configuration: **replaced**; current Authentik documentation removed
     Redis in 2025.10.
7. **Chart license review**: the official chart index identifies the chart as
   GPL-licensed. Distribution/adoption approval remains a release governance
   check; this module does not repackage or modify the chart.

## Interface Design

Flat release and namespace inputs remain clearer than grouping them. The
database fields form one unambiguous grouped object, with required connection
identity and optional port. `configuration_secret_name` is a separate required
reference because it is a distinct security boundary. There are no optional
pass-through fields; component sizing and advanced chart features require a
future approved extension.

| Input / output | Responsibility |
|---|---|
| `name` | Helm release and deterministic resource prefix; validated to keep the Service name legal. |
| `namespace` | Existing target namespace. |
| `chart_version` | Explicit approved chart version. |
| `database` | Non-secret external PostgreSQL connection metadata. |
| `configuration_secret_name` | Existing Secret holding Authentik's app key and DB password. |
| `release_*` outputs | Helm release identity/status/version. |
| `server_service_*` outputs | Internal HTTP endpoint for the separate ingress component. |

## Project Structure

```text
modules/authentik/
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
├── README.md
├── examples/basic/main.tf
└── tests/basic/
    ├── main.tf
    └── providers.tf

specs/011-shared-authentik/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
└── tasks.md
```

## Implementation Sequence

1. Create the strict module interface and input validation.
2. Render official chart values with external PostgreSQL and existing Secret
   semantics; use safe Helm lifecycle defaults.
3. Publish release and server-Service outputs only.
4. Add a neutral example and validate-only fixture; add the fixture to CI.
5. Document the prerequisite database/Secret contract and explicit non-goals.
6. Run format, Terraform validation, Helm rendering, and available static
   checks; capture any unavailable local gate rather than bypassing it.

## Risks and Stop Conditions

- If the official chart's Secret contract changes, stop before release and
  update the interface only after validating the upstream migration path.
- If a chart upgrade requires database migration strategy beyond Helm's normal
  release lifecycle, stop and define an explicit operational runbook.
- If consumers require ingress, automatic Secret generation, database creation,
  or arbitrary values to make v1 useful, stop for an explicit interface
  widening decision; do not add an escape hatch silently.
