# Implementation Plan: Shared Kubernetes Namespace Module

**Branch**: `010-shared-namespace` | **Date**: 2026-07-29 | **Spec**: [spec.md](spec.md)  
**Input**: DMVP-10317 feature specification.

## Summary

Create `modules/k8s/namespace`, a deliberately small Kubernetes-provider module
that creates exactly one pre-named namespace with optional labels and
annotations. It is the shared deployment boundary for platform components; it
does not own any workload, policy, secret, database, or ingress concern.

## Technical Context

**Terraform Version**: `~> 1.3`  
**Provider**: `hashicorp/kubernetes ~> 2.0`  
**Target Module Path**: `modules/k8s/namespace`
**Examples / Tests in Scope**: `modules/k8s/namespace/examples/basic`,
`modules/k8s/namespace/tests/basic`
**Automation Gates**: `terraform fmt`, `terraform init -backend=false`,
`terraform validate`, and all repository primary module matrices:
`terraform-test`, Checkov, TFLint, and pre-commit.
**Target Platform**: Existing Kubernetes cluster, configured by the caller  
**Constraints**: No customer names/hostnames/secrets; no namespace creation in
analytics modules; direct resource fallback only because no approved
provider-maintained wrapper exists for this Kubernetes primitive.  
**Scale/Scope**: One new shared module with documentation, example, and test.

## Constitution Check

- [x] The change has one coherent responsibility: a namespace identity and
  caller-owned metadata.
- [x] The consumer interface is opinionated and narrow; no upstream metadata
  pass-through or unrelated resources are exposed.
- [x] README, example, and test are included with the behavior.
- [x] Version/provider compatibility is explicit in `versions.tf`.
- [x] No breaking change, weakened default, or standards conflict is involved.

## Research Decisions

1. **Resource**: use `kubernetes_namespace_v1`. The official provider documents
   it as the supported namespace resource, with one required metadata block and
   optional annotations, labels, and default-service-account waiting.
2. **Interface**: flat `name`, `labels`, and `annotations` inputs are clearer
   than a grouped object for this three-field resource; no required/optional
   ambiguity is introduced.
3. **Default service account**: do not expose or wait for it in v1. Platform
   services must create/use their own service accounts; waiting would add an
   unrelated lifecycle dependency.
4. **Fallback rationale**: the approved AWS/Azure/GCP provider-maintained module
   collections do not supply a Kubernetes namespace wrapper. A direct provider
   resource is the bounded fallback.

## Project Structure

```text
modules/k8s/
├── grafana-dashboard.json
├── README.md
└── namespace/
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    ├── versions.tf
    ├── README.md
    ├── examples/basic/
    │   └── main.tf
    └── tests/basic/
        └── main.tf

specs/010-shared-namespace/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
└── tasks.md
```

**Structure Decision**: Group generic Kubernetes modules under `modules/k8s/`.
The existing `modules/k8s/grafana-dashboard.json` remains at its stable path as
a compatibility-preserving asset, while the namespace module is placed in its
own child directory. Keep `required_providers` in `versions.tf`, matching
maintained module patterns such as `modules/qdrant`.

## Validation Plan

1. Format the module, example, and test paths.
2. Initialize the module test fixture without a backend and run Terraform
   validation.
3. Run the repository's available pre-commit/quality checks for the changed
   paths.
4. Confirm the generated documentation and examples contain only neutral,
   non-secret values.
5. Verify the `modules/k8s/` routing documentation identifies the namespace
   module and the retained dashboard asset.
6. Register `modules/k8s/namespace` in the repository Terraform validation
   matrix and the Checkov, TFLint, and pre-commit matrices so CI validates the
   moved module path rather than its former location.
7. Validate the namespace input as a Kubernetes DNS-1123 label before the
   provider reaches the API; this preserves the input type and replacement
   lifecycle while failing invalid names early.

## Delivery Dependency

This module must be released before shared Authentik or analytics component
Setup YAMLs reference its namespace output. It is not a customer deployment by
itself.
