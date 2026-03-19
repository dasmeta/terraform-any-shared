# Module Housekeeping Exceptions

## Support-Only Path

| Target | Type | Reason | Impact | Review Trigger | Approval Required |
|--------|------|--------|--------|----------------|-------------------|
| `modules/k8s/` | support-only-directory | Contains repository assets rather than a consumer-facing Terraform module | Excluded from maintained-module workflow matrices | If a top-level module README or Terraform entrypoint is added | no |

## Approval-Gated Naming Conflicts

| Target | Type | Reason | Impact | Review Trigger | Approval Required |
|--------|------|--------|--------|----------------|-------------------|
| `modules/service/deploy.tf` | nonstandard-file-name | Renaming to `main.tf` could alter maintainer expectations for a known module layout | Retained until explicit approval is granted | If maintainers want full file-name normalization | yes |
| `modules/gateway-api-crds/locales.tf` | nonstandard-file-name | Name likely reflects local configuration intent, but it diverges from the preferred `locals.tf` pattern | Retained and documented instead of silently renamed | If module owners approve a rename | yes |
| `modules/kyverno/locales.tf` | nonstandard-file-name | Name likely reflects local configuration intent, but it diverges from the preferred `locals.tf` pattern | Retained and documented instead of silently renamed | If module owners approve a rename | yes |
| `modules/gitlab-runner/config.tf` | nonstandard-file-name | Renaming may be safe for Terraform, but the current file name may be relied on in contributor workflows | Retained until explicit approval is granted | If maintainers want full file-name normalization | yes |

## Support Artifact Exceptions

| Target | Type | Reason | Impact | Review Trigger | Approval Required |
|--------|------|--------|--------|----------------|-------------------|
| `modules/github-actions-runner/` | missing-example | No standardized example consumer exists yet | Excluded from `terraform-test` until example or dedicated tests are added | When `examples/` or `tests/` are introduced | no |
| `modules/goldilocks/` | missing-example | No standardized example consumer exists yet | Excluded from `terraform-test` until example or dedicated tests are added | When `examples/` or `tests/` are introduced | no |
| `modules/kafka/` | missing-example | No standardized example consumer exists yet | Excluded from `terraform-test` until example or dedicated tests are added | When `examples/` or `tests/` are introduced | no |
| `modules/minio/` | missing-example | No standardized example consumer exists yet | Excluded from `terraform-test` until example or dedicated tests are added | When `examples/` or `tests/` are introduced | no |
| `modules/mongodb/` | missing-example | No standardized example consumer exists yet | Excluded from `terraform-test` until example or dedicated tests are added | When `examples/` or `tests/` are introduced | no |
| `modules/supabase/` | missing-example | No standardized example consumer exists yet | Excluded from `terraform-test` until example or dedicated tests are added | When `examples/` or `tests/` are introduced | no |
| `modules/defectdojo/`, `modules/event-exporter/`, `modules/gateway-api-crds/`, `modules/gitlab-runner/`, `modules/horizon-monitor/`, `modules/istio/`, `modules/keeper-reader/`, `modules/kyverno/`, `modules/loki/`, `modules/onepassword/`, `modules/onepassword_to_secret_manager/`, `modules/renovate-bot/`, `modules/sentry/`, and `modules/service/` | missing-test | Maintained modules rely on examples or documented validation rather than dedicated `tests/` directories | Still covered by static validation; follow-up test harness work remains explicit | When dedicated test scaffolding is introduced | no |

## Validation Exceptions

| Target | Type | Reason | Impact | Review Trigger | Approval Required |
|--------|------|--------|--------|----------------|-------------------|
| `terraform-test` coverage for `modules/github-actions-runner/`, `modules/goldilocks/`, `modules/kafka/`, `modules/minio/`, `modules/mongodb/`, and `modules/supabase/` | validation-exclusion | These modules do not yet expose standardized example or test scaffolding suitable for the current `terraform-test` workflow | They remain covered by `checkov`, `tflint`, `pre-commit`, and `tfsec` while `terraform-test` is intentionally partial | When example or test scaffolding is added | no |
