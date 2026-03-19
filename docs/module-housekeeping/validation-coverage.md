# Validation Coverage

## Workflow Summary

| Validation | Coverage | Status | Notes |
|------------|----------|--------|-------|
| `.github/workflows/checkov.yaml` | 22 maintained top-level modules | aligned | Support-only `modules/k8s/` excluded |
| `.github/workflows/tflint.yaml` | 22 maintained top-level modules | aligned | Support-only `modules/k8s/` excluded |
| `.github/workflows/pre-commit.yaml` | 22 maintained top-level modules | aligned | Matrix handling repaired and path scope normalized |
| `.github/workflows/terraform-test.yaml` | 16 maintained modules with standardized example/test scaffolding | partial | Six modules remain excluded pending example/test support |
| `.github/workflows/tfsec.yaml` | repo-wide Terraform files | aligned | Complements module-scoped workflows |
| `.pre-commit-config.yaml` | repo-wide formatting and terraform-docs expectations | aligned | Local validation baseline retained and clarified |

## Maintained Modules Covered by Matrix Workflows

The following top-level maintained modules are covered by `checkov`, `tflint`,
and `pre-commit`:

- `modules/defectdojo`
- `modules/event-exporter`
- `modules/gateway-api-crds`
- `modules/github-actions-runner`
- `modules/gitlab-runner`
- `modules/goldilocks`
- `modules/horizon-monitor`
- `modules/istio`
- `modules/kafka`
- `modules/keeper-reader`
- `modules/kyverno`
- `modules/loki`
- `modules/minio`
- `modules/mongodb`
- `modules/mongodb-bi-connector`
- `modules/onepassword`
- `modules/onepassword_to_secret_manager`
- `modules/qdrant`
- `modules/renovate-bot`
- `modules/sentry`
- `modules/service`
- `modules/supabase`

## `terraform-test` Coverage

`terraform-test` is currently mapped to maintained modules with standardized
example or test scaffolding:

- `modules/defectdojo`
- `modules/event-exporter`
- `modules/gateway-api-crds`
- `modules/gitlab-runner`
- `modules/horizon-monitor`
- `modules/istio`
- `modules/keeper-reader`
- `modules/kyverno`
- `modules/loki`
- `modules/mongodb-bi-connector`
- `modules/onepassword`
- `modules/onepassword_to_secret_manager`
- `modules/qdrant`
- `modules/renovate-bot`
- `modules/sentry`
- `modules/service`

Excluded modules are tracked in `exceptions.md`.
