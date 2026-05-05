# Quickstart: Keycloak module production readiness

**Created**: 2026-05-05  
**Feature**: `specs/005-keycloak-module-review/spec.md`

## Goal

Validate the production readiness changes in `modules/keycloak` without committing environment-specific secrets.

## Local validation (syntax / formatting)

```bash
cd modules/keycloak
terraform fmt -recursive
terraform validate
```

## Cluster smoke test (example)

1. Edit `modules/keycloak/examples/basic/1-example.tf` locally with:
   - a **test namespace**, **test hostname**, and **test database**
   - real secrets (do not commit)
2. Ensure providers in `modules/keycloak/examples/basic/0-setup.tf` reference a working kubeconfig.
3. Apply:

```bash
cd modules/keycloak/examples/basic
terraform init
terraform plan
terraform apply
```

## Observability checks

- Prometheus targets show Keycloak metrics when scraping is configured.
- Login failure rate can be derived from event metrics (when enabled).
- `/health/ready` reports readiness after initialization.

