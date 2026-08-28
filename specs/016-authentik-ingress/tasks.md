# Tasks: Optional Authentik ingress

## Phase 1: Test contract

- [X] T001 Add enabled-ingress assertions to `modules/authentik/tests/invalid_inputs.tftest.hcl`.
- [X] T002 Add missing-enabled-ingress-field validation tests to `modules/authentik/tests/invalid_inputs.tftest.hcl`.

## Phase 2: Module behavior

- [X] T003 [US1] Add the typed ingress input and enablement validation in `modules/authentik/variables.tf`.
- [X] T004 [US1] Render the official server ingress values and reserved TLS annotations in `modules/authentik/main.tf`.

## Phase 3: Consumer documentation

- [X] T005 [P] [US1] Add a TLS ingress example to `modules/authentik/examples/basic/main.tf`.
- [X] T006 [P] [US1] Document ingress, TLS and external DNS boundaries in `modules/authentik/README.md`.

## Phase 4: Validation

- [X] T007 Run formatting and Terraform tests for `modules/authentik`.
- [X] T008 Render the official chart with enabled ingress values and confirm the Ingress/TLS manifest.
- [X] T009 Mark completed tasks and record validation evidence in this file.

## Review follow-up

- [X] T010 Preserve legacy `extra_helm_config.server.ingress` values when the typed ingress input is omitted in `modules/authentik/main.tf`.
- [X] T011 Restrict the typed ingress implementation to NGINX and accept a null ingress input in `modules/authentik/variables.tf`.
- [X] T012 Add compatibility and Kubernetes-name validation coverage in `modules/authentik/tests/invalid_inputs.tftest.hcl`.

## Module standards follow-up

- [X] T013 Record wrapper, version, modern-capability and module-change-gate evidence in `specs/016-authentik-ingress/plan.md`.
- [X] T014 Add inline descriptions to every grouped ingress field in `modules/authentik/variables.tf`.

## Validation Evidence

- `terraform fmt -recursive modules/authentik`: passed.
- `terraform -chdir=modules/authentik test`: passed, four tests including
  enabled-ingress and missing-ingress-detail coverage.
- `terraform -chdir=modules/authentik/tests/basic validate`: passed.
- `terraform -chdir=modules/authentik/examples/basic init -backend=false` and
  `terraform validate`: passed.
- `helm template` with the enabled ingress values rendered an NGINX Ingress,
  cert-manager issuer annotation, HTTPS redirect and expected TLS Secret.
- `checkov -d modules/authentik --quiet`: passed.
- `pre-commit` and `tflint` are not installed locally; CI remains the lint and
  repository-hook gate.
