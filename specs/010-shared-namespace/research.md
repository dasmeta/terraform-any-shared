# Research: Shared Kubernetes Namespace Module

## Provider Baseline

The official HashiCorp Kubernetes provider documents `kubernetes_namespace_v1`
as the current namespace resource. It requires namespace metadata and supports
optional labels and annotations. Namespace names cannot be updated, so a name
change naturally plans a replacement rather than a silent rename.

Source: <https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace_v1>

## Wrapper Decision

The approved provider-maintained module collections cover AWS, Azure, and GCP,
not this Kubernetes primitive. The module therefore uses one direct provider
resource rather than introducing a public-module dependency or copying an
unrelated template.

## Modern Capability Classification

| Ability | Classification | Decision |
| --- | --- | --- |
| Namespace creation | supported | Use `kubernetes_namespace_v1`. |
| Labels and annotations | supported | Pass typed maps into metadata. |
| Default service-account waiting | supported, excluded | Not needed for this module's namespace-only responsibility. |

## Interface Decision

The interface is flat rather than a grouped object: one required `name` and two
optional metadata maps. Grouping adds no clarity and would require callers to
navigate an unnecessary object for a single resource.
