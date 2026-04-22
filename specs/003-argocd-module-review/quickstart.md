# Quickstart: Argo CD module review & hardening

**Date**: 2026-04-21  
**Module**: `modules/argocd`

## Goal

Deploy Argo CD to an existing Kubernetes cluster using the `modules/argocd` wrapper and validate basic reachability.

## Prerequisites

- A reachable Kubernetes cluster
- Helm connectivity to the cluster
- (For ALB ingress) AWS Load Balancer Controller installed in the cluster

## Run the example

From the repository root:

```bash
cd modules/argocd/examples/basic
terraform init
terraform apply
```

## Validate

```bash
kubectl -n argocd get pods
kubectl -n argocd get ingress
```

## Notes

- When ingress is enabled, you must set a `hostname`.
- Admin credential mode must be exactly one of:
  - `use_existing_admin_secret=true` (recommended), or
  - `admin_password_bcrypt` for bootstrap/testing.
- Use `extra_configs` if you need an upstream chart option not covered by module inputs.
