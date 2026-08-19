# Research: Shared Authentik deployment module

## Sources checked

- Official Kubernetes installation guide:
  <https://docs.goauthentik.io/install-config/install/kubernetes/>.
- Official configuration reference:
  <https://docs.goauthentik.io/install-config/configuration/>.
- Official chart values and templates for `authentik` chart `2026.5.6`, fetched
  from `https://charts.goauthentik.io` on 2026-07-29.
- Official 2025.10 release notes:
  <https://docs.goauthentik.io/releases/2025.10/>.

## Findings

1. The official Kubernetes guide requires external PostgreSQL for production;
   bundled PostgreSQL is only appropriate for test/demo use.
2. `authentik.existingSecret.secretName` causes both server and worker to load
   the named Secret through `envFrom`. It also means `authentik.*` values are
   ignored for creating configuration, so non-secret database metadata must be
   supplied through the chart's supported `global.env` entries.
3. The chart converts `authentik` values to `AUTHENTIK_*` environment keys.
   Therefore a referenced Secret needs `AUTHENTIK_SECRET_KEY` and
   `AUTHENTIK_POSTGRESQL__PASSWORD` for this module's configuration.
4. `postgresql.enabled` defaults false in the current chart and is explicitly
   set false by the wrapper to preserve the external-database boundary.
5. `fullnameOverride` controls the chart full name; the server Service is
   `<fullname>-<server.name>`, with `server.name` defaulting to `server`.
6. Authentik 2025.10 removed Redis. The module must not introduce an obsolete
   Redis dependency.

## Decision

Use one `helm_release` with values encoded from a typed, opinionated interface.
Do not create Kubernetes resources or use secret values in Terraform. The
consumer supplies only the Secret name, while its secret manager owns the app
key and database password; the module injects only non-secret database metadata.
