# Quickstart: Implement Plan 004

## 1) Confirm workspace state
1. Ensure branch is `004-upgrade-istio-gateway-api`.
2. Ensure feature artifacts exist under `specs/004-upgrade-istio-gateway-api/`.
3. Baseline defaults before change:
   - `modules/istio`: fallback `chart_version` was `1.29.1`, gateway-api chart `0.1.4`
   - `modules/gateway-api-crds`: default `version` was `v1.5.0`

## 2) Update Istio module behavior
1. Update `modules/istio` inputs to support per-component image overrides for `base`, `istiod`, and `gateway`.
2. Keep defaults equivalent to existing behavior when overrides are not set.
3. Update default chart versions to approved latest stable values.
4. Add/adjust validation for incomplete component overrides.

## 3) Update Gateway API CRD module behavior
1. Update CRD default version and `crdsList` to approved latest stable baseline.
2. Remove `modules/gateway-api-crds/locales.tf` if it has no active references.
3. Ensure any remaining references resolve cleanly after removal.

## 4) Update module documentation and examples
1. Update `modules/istio/README.md` with any new input semantics and defaults.
2. Update `modules/gateway-api-crds/README.md` with explicit CRD YAML + `version`/`crdsList` upgrade steps.
3. Update affected examples to reflect supported interface and defaults.

## 5) Validate
1. Run Terraform formatting:
   - `terraform fmt -recursive modules/istio modules/gateway-api-crds`
2. Run docs/format hooks:
   - `pre-commit run terraform_fmt --all-files`
   - `pre-commit run terraform_docs --all-files`
3. Run plan/validation for affected module examples.
   - `cd modules/istio/examples/basic && terraform init && terraform validate`
   - `cd modules/gateway-api-crds/examples/basic && terraform init && terraform validate`
3. Verify:
   - default consumer flow remains valid
   - per-component overrides work independently
   - CRD version contract is consistent

## 6) Prepare for tasks phase
1. Confirm plan, research, data model, contracts, and quickstart files are present.
2. Move to `/speckit.tasks`.
