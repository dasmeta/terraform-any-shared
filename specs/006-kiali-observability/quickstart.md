# Quickstart: Implement Plan 006

## 1) Confirm workspace and feature context
1. Ensure active branch context is `006-kiali-observability`.
2. Ensure artifacts exist under `specs/006-kiali-observability/`:
   - `spec.md`
   - `plan.md`
   - `research.md`
   - `data-model.md`
   - `contracts/module-interface.md`
3. Confirm current in-scope module paths:
   - `modules/kiali`
   - `modules/istio`

## 2) Implement module behavior updates
1. Finalize `modules/kiali` operator + Kiali CR behavior for Prometheus/Grafana common settings.
2. Ensure `modules/istio` optional delegation to `modules/kiali` remains backward-compatible by default.
3. Ensure Kiali server image overrides (`configs.kiali.image.server.*`) are effective with operator behavior (including ad-hoc image allowance where required).

## 3) Update documentation and examples
1. Update `modules/kiali/README.md` and `modules/istio/README.md` for current interface shape.
2. Keep `modules/istio/examples/kiali-observability` aligned with current delegation contract.
3. Update `modules/istio/examples/custom-chart-and-image-overrides` to include Kiali customization per FR-009.

## 4) Validate
1. Run formatting:
   - `terraform fmt -recursive modules/kiali modules/istio`
2. Run pre-commit checks:
   - `pre-commit run terraform_fmt --all-files`
   - `pre-commit run terraform_docs --all-files`
3. Run targeted example checks where provider initialization is available:
   - `cd modules/kiali/examples/basic && terraform init && terraform validate`
   - `cd modules/istio/examples/kiali-observability && terraform init && terraform validate`
   - `cd modules/istio/examples/custom-chart-and-image-overrides && terraform init && terraform validate`

## 5) Prepare for tasks phase
1. Confirm no unresolved spec/plan ambiguities remain.
2. Proceed to task generation with `/speckit.tasks`.
