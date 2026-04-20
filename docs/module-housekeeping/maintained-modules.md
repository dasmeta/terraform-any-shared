# Maintained Module Inventory

## Top-Level Inventory

| Path | Classification | README | Examples | Tests | Validation | Status | Notes |
|------|----------------|--------|----------|-------|------------|--------|-------|
| `modules/defectdojo/` | maintained | normalized | `examples/basic` | exception | covered | aligned | Helm module with documented example path |
| `modules/event-exporter/` | maintained | normalized | `examples/` | exception | covered | aligned | Example README normalized |
| `modules/gateway-api-crds/` | maintained | normalized | `examples/basic` | exception | covered | excepted | Keeps `locales.tf` pending explicit approval |
| `modules/github-actions-runner/` | maintained | normalized | exception | exception | covered | excepted | No standardized example or test harness yet |
| `modules/gitlab-runner/` | maintained | existing | `examples/cache-pvc` | exception | covered | excepted | Keeps `config.tf` pending explicit approval |
| `modules/goldilocks/` | maintained | normalized | exception | exception | covered | excepted | Example/test scaffolding still documented as an exception |
| `modules/horizon-monitor/` | maintained | existing | `examples/basic` | exception | covered | aligned | Example scaffold already present |
| `modules/istio/` | maintained | existing | multiple examples | exception | covered | aligned | Strong example coverage already present |
| `modules/kafka/` | maintained | normalized | exception | exception | covered | excepted | No standardized example/test harness yet |
| `modules/keeper-reader/` | maintained | normalized | `examples/basic` | exception | covered | aligned | Nested submodules remain in scope of this maintained family |
| `modules/kyverno/` | maintained | existing | `examples/basic` | exception | covered | excepted | Keeps `locales.tf` pending explicit approval |
| `modules/loki/` | maintained | existing | multiple examples | exception | covered | aligned | Version file normalized to `versions.tf` |
| `modules/minio/` | maintained | normalized | exception | exception | covered | excepted | No standardized example/test harness yet |
| `modules/mongodb/` | maintained | normalized | exception | exception | covered | excepted | No standardized example/test harness yet |
| `modules/mongodb-bi-connector/` | maintained | existing | exception | `tests/basic` | covered | aligned | Uses tests instead of example scaffolding |
| `modules/onepassword/` | maintained | normalized | `examples/` | exception | covered | aligned | Example README normalized |
| `modules/onepassword_to_secret_manager/` | maintained | normalized | `examples/basic` | exception | covered | aligned | Singular example path normalized |
| `modules/qdrant/` | maintained | existing | exception | `tests/basic`, `tests/helm_config_overwrite` | covered | aligned | Version file normalized to `versions.tf` |
| `modules/renovate-bot/` | maintained | existing | `examples/basic` | exception | covered | aligned | Strong baseline coverage already present |
| `modules/argocd/` | maintained | normalized | `examples/basic` | exception | covered | aligned | Helm module for Argo CD with AWS ALB ingress wrapper |
| `modules/sentry/` | maintained | normalized | `examples/basic` | exception | covered | aligned | README preamble added |
| `modules/service/` | maintained | normalized | `examples/basic` | exception | covered | excepted | Keeps `deploy.tf` pending explicit approval |
| `modules/supabase/` | maintained | normalized | exception | exception | covered | excepted | No standardized example/test harness yet |
| `modules/k8s/` | support-only | n/a | n/a | n/a | repo-wide only | excepted | Asset directory, not a consumer-facing Terraform module |

## Nested Module Families

| Path | Classification | Status | Notes |
|------|----------------|--------|-------|
| `modules/keeper-reader/modules/` | maintained family internals | aligned | Covered through the maintained `keeper-reader` module family |
| `modules/onepassword/module/get-data/` | maintained family internals | aligned | Covered through the maintained `onepassword` module family |

## Review Summary

- Maintained top-level module paths: 23
- Support-only top-level paths: 1
- Explicitly excepted maintained modules: 9
- Fully aligned maintained modules: 14
