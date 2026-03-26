# Quickstart: Keycloak Helm Wrapper Module

## Goal

Implement `modules/keycloak` as a maintained Terraform Helm wrapper for the
standard Keycloak deployment path: external database, curated ingress support,
explicit bootstrap credential handling, and repository-aligned validation.

## Prerequisites

- Work from branch `002-keycloak-module`
- Review:
  - `spec.md`
  - `plan.md`
  - `research.md`
  - `data-model.md`
  - `contracts/keycloak-module-interface.md`
  - `contracts/keycloak-validation-scope.md`
- Have a reachable Kubernetes context available if you intend to run Helm-based
  example flows beyond static validation

## Execution Steps

1. Scaffold the module
   - create `modules/keycloak/main.tf`, `variables.tf`, `outputs.tf`,
     `versions.tf`, and `README.md`
   - pin Terraform and provider compatibility explicitly
   - establish the `codecentric/keycloakx` chart as the only upstream baseline

2. Implement the curated interface
   - add release identity, namespace, hostname/ingress, external database, and
     bootstrap credential inputs
   - reject broad values pass-through inputs
   - implement secret-source selection so existing Secret references are the
     preferred path and conflicting input modes fail validation

3. Add support artifacts
   - create `modules/keycloak/examples/basic/` for one supported deployment
     path
   - create `modules/keycloak/tests/basic/` for one Terraform validation path
   - document prerequisites and unsupported capabilities in `README.md`

4. Align repository validation
   - add `modules/keycloak` to `checkov`, `tflint`, and `terraform-test`
     workflow matrices
   - regenerate terraform-docs content and reconcile any pre-commit changes

## Validation Commands

Run these after implementation:

```bash
terraform fmt -check -recursive modules/keycloak
terraform -chdir=modules/keycloak init -backend=false
terraform -chdir=modules/keycloak validate
terraform -chdir=modules/keycloak/examples/basic init -backend=false
terraform -chdir=modules/keycloak/examples/basic validate
terraform -chdir=modules/keycloak/tests/basic init -backend=false
terraform -chdir=modules/keycloak/tests/basic validate
PRE_COMMIT_HOME=/tmp/pre-commit-cache python3 -m pre_commit run --all-files
git diff -- modules/keycloak .github/workflows .pre-commit-config.yaml AGENTS.md
```

If `pre-commit` rewrites README content or formatting, rerun it until the tree
stabilizes.

## Expected Review Outcome

- Reviewers can identify the supported deployment path and required inputs from
  the README and basic example without reading module internals
- The module stays within a curated wrapper boundary and does not expose the
  full upstream chart surface
- Workflow coverage treats `modules/keycloak` as a maintained module
- Validation makes conflicting bootstrap credential configurations explicit
