# terraform-any-shared Development Guidelines

Auto-generated from all feature plans. Last updated: 2026-08-05

## Active Technologies
- Terraform ~> 1.3 + Gavinbunney Kubectl provider, CloudNativePG Cluster CRs, GitHub Actions, pre-commit, terraform-docs, tflint, checkov (012-add-cnpg-module)
- Terraform ~> 1.3 + Helm provider, Kubernetes provider, GitHub Actions, pre-commit, terraform-docs, tflint, checkov (002-keycloak-module)
- Consumer-managed external database; Kubernetes Secret-backed bootstrap credentials (002-keycloak-module)

- Terraform ~> 1.3 + GitHub Actions, pre-commit, terraform-docs, tflint, (001-standardize-module-housekeeping)

## Project Structure

```text
src/
tests/
```

## Commands

# Add commands for Terraform ~> 1.3

## Code Style

Terraform ~> 1.3: Follow standard conventions

## Recent Changes
- 012-add-cnpg-module: Added the shared cluster-only CNPG module with existing Secret references and non-secret read/write and read-only service outputs.

- 002-keycloak-module: Added Terraform ~> 1.3 + Helm provider, Kubernetes provider, GitHub Actions, pre-commit, terraform-docs, tflint, checkov

- 001-standardize-module-housekeeping: Added Terraform ~> 1.3 + GitHub Actions, pre-commit, terraform-docs, tflint,

<!-- MANUAL ADDITIONS START -->
## Skill Enforcement For Module Development

- For any Terraform module creation/extension/standardization work in this repository (for example changes in `modules/**`, module `README.md`, `examples/**`, `tests/**`, or module automation), the agent must use the `terraform-module-developer` skill when available.
- Treat this as required process guidance, not optional preference.
- Keep Speckit-first workflow for module-impacting changes and ensure related spec/plan/tasks artifacts are present or updated before substantial module interface/behavior edits.
- If a requested change is breaking or materially widens module interface, stop and ask for explicit approval before implementing.
<!-- MANUAL ADDITIONS END -->
