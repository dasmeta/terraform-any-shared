# Research: SFTPGo Terraform Module

## Decision: Wrap the upstream SFTPGo Helm chart directly

**Rationale**: The requested deliverable is a Kubernetes Helm deployment module. The upstream SFTPGo Helm chart is the correct baseline for SFTPGo Kubernetes resources, while this repository should provide the reusable opinionated Terraform interface around it.

**Alternatives considered**:

- Reuse the generic `service` module: rejected because SFTPGo needs repeatable S3/user bootstrap behavior, sensitive grouped inputs, and documented defaults that should live in a dedicated shared module.
- Direct Kubernetes resources: rejected because a maintained Helm chart exists and repository standards prefer wrapping an upstream chart/module before recreating equivalent resources.

## Decision: Require S3-backed bootstrap user storage in the first interface

**Rationale**: The ticket refinement confirmed S3 storage should be part of the initial reusable deployment path. Making it required keeps the first version deterministic and avoids ambiguous PVC-only behavior.

**Alternatives considered**:

- Optional local/PVC-only mode: rejected for this ticket because it expands scope and validation paths beyond the confirmed requirement.

## Decision: Use sensitive Terraform variables for bootstrap secrets

**Rationale**: The ticket refinement confirmed Terraform variables should carry admin password, user passwords, and S3 access secret. Variables will be marked `sensitive = true`; README will document that values still reside in Terraform state.

**Alternatives considered**:

- Existing Kubernetes Secret references: rejected for this ticket because the requested mode is Terraform variables.

## Decision: Use grouped object variables

**Rationale**: SFTPGo configuration has clear boundaries: S3 storage, bootstrap users, persistence, ingress, resources, and deployment behavior. Grouped objects reduce top-level input sprawl and match internal module standards for clear consumer interfaces.

**Alternatives considered**:

- Many flat variables: rejected because it would be harder to review and less consistent with current grouped wrapper guidance.

## Decision: Generate bootstrap sidecar values in Terraform locals

**Rationale**: User bootstrap requires procedural API calls after SFTPGo is ready. Packaging this as generated Helm values keeps the consumer interface declarative while avoiding repeated copy-paste in downstream repositories.

**Alternatives considered**:

- Document manual post-install user creation: rejected because the ticket asks for reusable bootstrap support.
- Separate Kubernetes Job resource: deferred because the current working example uses chart `extraContainers`, and the chart-supported values path keeps ownership inside the Helm deployment.
