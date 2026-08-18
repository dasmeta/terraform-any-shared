# Feature Specification: Extend Legacy GitHub Actions Runners

**Feature Branch**: `018-extend-actions-runners`
**Created**: 2026-08-18
**Status**: Draft
**Input**: User description: "Patch the existing GitHub Actions runner module for DasMeta YAML infrastructure and Terraform Cloud credentials, add multiple-repository or organization scope, and preserve existing consumers where possible."

## Module Context *(mandatory)*

- **Target Module Path**: `modules/github-actions-runner`
- **Related Files In Scope**: module Terraform files, the runner manifest template,
  `README.md`, new generic examples or tests, and module validation coverage records
  when the new executable coverage closes the current exception.
- **Upstream Baseline**: the existing legacy Actions Runner Controller Helm chart
  and `actions.summerwind.dev/v1alpha1` runner resource. Migration to runner scale
  sets is outside this change.
- **Requested Interface Change**: retain the existing single-repository inputs;
  add optional multiple-repository and organization targeting, configurable
  namespace and chart version, pre-existing authentication Secret support, and
  provider behavior compatible with Terraform Cloud-injected Kubernetes
  credentials.
- **Breaking Change / Interface Widening**: interface widening is explicitly
  requested and approved. Breaking changes are not approved; existing callers
  using one repository, a personal access token, and a kubeconfig path must keep
  their current behavior.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Deploy Through YAML Infrastructure (Priority: P1)

An infrastructure operator can consume the module from a YAML-defined Setup
whose Terraform Cloud workspace already receives Kubernetes credentials. The
operator can reference an existing in-cluster GitHub authentication Secret and
does not need to commit a token or depend on a developer workstation kubeconfig.

**Why this priority**: This is required to deploy the runner through the active
DasMeta infrastructure workflow safely.

**Independent Test**: Render and validate a generic YAML-compatible module
consumer with no token value and no local kubeconfig path, using an existing
authentication Secret name and provider credentials supplied outside the module.

**Acceptance Scenarios**:

1. **Given** a workspace with Kubernetes provider credentials and a valid
   authentication Secret, **When** the operator configures the module without a
   personal access token, **Then** the controller references the existing Secret
   and no GitHub credential is embedded in module configuration.
2. **Given** provider credentials supplied by the execution environment, **When**
   the operator explicitly disables local kubeconfig-path usage, **Then** module
   resources use those credentials successfully.
3. **Given** neither a personal access token nor an existing authentication
   Secret, **When** configuration is validated, **Then** validation fails with a
   clear authentication requirement.

---

### User Story 2 - Choose Repository or Organization Scope (Priority: P2)

An operator can register legacy runners for one repository, several explicitly
listed repositories, or one organization without duplicating module blocks.

**Why this priority**: A shared runner should serve the intended Galust delivery
scope without requiring repetitive infrastructure Setups.

**Independent Test**: Validate three generic configurations: one legacy
repository, multiple repositories, and one organization. Each configuration must
produce only the intended runner registrations.

**Acceptance Scenarios**:

1. **Given** only the existing repository input, **When** the module is applied,
   **Then** it produces the same single repository-scoped runner contract as
   before.
2. **Given** two or more repository targets, **When** the module is applied,
   **Then** it creates one predictably named runner registration for each target.
3. **Given** one organization target, **When** the module is applied, **Then** it
   creates one organization-scoped runner registration available according to
   GitHub organization runner access controls.
4. **Given** repository and organization targets together, **When** configuration
   is validated, **Then** validation fails instead of choosing a scope silently.

---

### User Story 3 - Preserve Existing Consumers (Priority: P3)

An existing module consumer can upgrade without renaming its inputs or changing
its single-repository runner behavior.

**Why this priority**: The shared module may already have consumers that are not
represented in the current repository examples.

**Independent Test**: Validate the historical input shape and compare its
rendered runner target, name, namespace, and authentication behavior with the
current contract.

**Acceptance Scenarios**:

1. **Given** the historical inputs for runner name, repository, personal access
   token, and kubeconfig path, **When** the updated module is evaluated, **Then**
   those inputs remain accepted and retain their previous meanings.
2. **Given** no newly added scope inputs, **When** the module is evaluated,
   **Then** the existing repository input remains the effective target.
3. **Given** the existing default namespace, **When** no namespace override is
   provided, **Then** controller and runner resources retain that namespace.

### Edge Cases

- Repository target names from different owners must not produce colliding
  Kubernetes resource names.
- Generated names must remain valid when repository or organization identifiers
  contain uppercase letters, underscores, dots, or long paths.
- Duplicate repository targets must not create duplicate runner resources.
- An empty repository collection must fall back to the existing repository input.
- Empty strings must not count as valid repository, organization, Secret, or
  token values.
- Supplying both a token and an existing Secret must fail rather than create an
  ambiguous authentication source.
- Multiple repository targets and organization scope are mutually exclusive.
- Optional chart-version pinning must not change existing unpinned consumers.
- A failed controller installation must prevent runner manifests from being
  treated as successfully ready.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The module MUST remain focused on deploying the legacy GitHub
  Actions Runner Controller and its runner registrations into one Kubernetes
  cluster.
- **FR-002**: The module MUST preserve the existing `runner_name`, `repo_name`,
  `personal_access_token`, and `kubectl_config_path` consumer inputs.
- **FR-003**: When no new scope input is supplied, the module MUST require an
  explicit, non-empty `repo_name` and produce one repository-scoped runner.
- **FR-004**: The module MUST accept a deduplicated collection of repository
  targets and create one stable runner registration per target.
- **FR-005**: The module MUST accept one organization target and create one
  organization-scoped runner registration.
- **FR-006**: The module MUST reject configuration that combines organization
  targeting with repository targeting.
- **FR-007**: The module MUST generate deterministic, unique, Kubernetes-valid
  names for multiple repository targets while retaining the historical runner
  name for the legacy single-repository path.
- **FR-008**: The module MUST support either the existing personal access token
  flow or a reference to a pre-existing controller authentication Secret.
- **FR-009**: The module MUST reject configurations with zero or multiple active
  authentication sources.
- **FR-010**: Personal access token input MUST be treated as sensitive in module
  output and plan presentation.
- **FR-011**: A pre-existing authentication Secret MUST remain externally
  managed; the module MUST only reference it and document the expected namespace
  and key contract.
- **FR-012**: The module MUST allow local kubeconfig-path use to be disabled so
  Kubernetes credentials supplied by the execution environment can take effect;
  disabling the path MUST also disable local kubeconfig loading so the provider
  does not fall back to an unavailable default file during remote apply.
- **FR-013**: Existing consumers that pass a kubeconfig path MUST retain that
  behavior.
- **FR-014**: The module MUST allow the deployment namespace to be overridden
  while retaining the existing namespace as its default.
- **FR-015**: The module MUST allow an optional legacy controller chart version
  pin while preserving the existing unpinned behavior when omitted.
- **FR-016**: Controller installation MUST complete before runner manifests are
  applied.
- **FR-017**: The module MUST expose the effective runner resource names and
  targeting mode for operator verification.
- **FR-018**: Documentation and examples MUST use only generic or DasMeta-safe
  identifiers and MUST NOT include real credentials.
- **FR-019**: Scoped runner names MUST remain unique when two module instances
  use different full runner names that share the same truncated prefix and
  target the same repository or organization.
- **FR-020**: Documentation MUST state that the retained internal kubectl
  provider makes the legacy module incompatible with module-level `count`,
  `for_each`, and `depends_on`.
- **FR-021**: Documentation MUST explain that migrating from `repo_name` to
  `runner_scope.repositories` replaces the historical Runner resource.
- **FR-022**: The executable example MUST pin the legacy controller chart to a
  known version.

### Compatibility & Delivery Requirements

- **CDR-001**: Scope is limited to `modules/github-actions-runner`, directly
  related generic examples/tests, documentation, and validation coverage records.
- **CDR-002**: The legacy upstream controller is intentionally preserved because
  the target cluster is old and the requester explicitly selected this path;
  modern scale-set migration is a separate future change.
- **CDR-003**: Validation MUST cover formatting, initialization, static
  validation, and independently verifiable legacy single-repository,
  multiple-repository, organization, external-Secret, and invalid-combination
  cases.
- **CDR-004**: Documentation MUST distinguish credentials used to reach the
  Kubernetes cluster from GitHub controller authentication and explain how a
  YAML/Terraform Cloud consumer supplies each.
- **CDR-005**: The plan MUST record the legacy-controller exception for net-new
  multi-target and organization abilities and cite upstream platform evidence.
- **CDR-006**: The implementation MUST NOT add Galust-specific names to the
  reusable module, examples, tests, or documentation.
- **CDR-007**: A consumer Setup in another repository remains a separate delivery
  step and MUST use a released module version rather than an unreleased source.
- **CDR-008**: Removing the customer-specific `repo_name` default is an approved
  safety-breaking change. The input name and explicit legacy behavior remain,
  but configurations that relied on the implicit target must now set one.
- **CDR-009**: Removing the internal kubectl provider is deferred to a future
  major release because it would break consumers that rely on the module-owned
  provider configuration. This change documents the resulting limitation.

### Key Entities

- **Runner Scope**: The mutually exclusive target selection: historical single
  repository, an explicit repository collection, or one organization.
- **Authentication Source**: Either a supplied personal access token or a
  reference to an externally managed Kubernetes Secret containing the GitHub
  controller credential.
- **Runner Registration**: A predictably named legacy runner resource associated
  with exactly one repository or organization scope.
- **Cluster Credential Source**: Either an explicitly supplied local kubeconfig
  path or provider credentials injected by the execution environment.

## Assumptions

- The existing cluster can run the currently selected legacy controller and its
  `actions.summerwind.dev/v1alpha1` custom resources.
- One organization-scoped runner registration is sufficient initially; runner
  autoscaling and replica management are outside this change.
- GitHub organization runner access remains governed in GitHub and is not
  broadened automatically by this module.
- The external authentication Secret exists in the controller namespace and
  contains the key expected by the legacy controller chart.
- The infrastructure consumer will attach its existing Kubernetes credential
  variable set and will explicitly disable local kubeconfig-path use.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: All five supported examples—legacy single repository, multiple
  repositories, organization scope, external Secret authentication, and
  environment-provided cluster credentials—validate without real credentials.
- **SC-002**: Invalid mixed-scope and mixed-authentication configurations fail
  before creating controller or runner resources.
- **SC-003**: A historical single-repository configuration requires zero input
  renames and retains its target, runner name, namespace, and token-based
  authentication behavior.
- **SC-004**: Two distinct repository targets always produce two distinct,
  Kubernetes-valid runner resource names across repeated plans.
- **SC-005**: Module formatting, initialization, validation, documentation, and
  repository security/static-analysis gates pass for the affected paths.
- **SC-006**: No personal access token, private key, kubeconfig content, or
  customer-specific identifier is committed in module artifacts.
