# Research: Extend Legacy GitHub Actions Runners

## Decision: Preserve legacy `Runner` resources

**Rationale**: The current module and target cluster already use the legacy
controller API. The official legacy schema supports mutually exclusive
`repository` and `organization` fields, so the requested target modes can be
added without changing controller families or resource semantics.

**Alternatives considered**:

- Modern ARC runner scale sets: preferred for a new platform, but rejected here
  because the requester explicitly selected the legacy controller for an older
  cluster.
- `RunnerDeployment`: rejected because it changes the current persistent Runner
  resource kind and introduces replica/deployment lifecycle semantics not needed
  for the requested single-runner capacity.
- Repeated module instances: rejected because each instance would manage the
  same controller Helm release and namespace.

## Decision: Add one grouped scope input with legacy fallback

**Rationale**: Repository collections and an organization are mutually exclusive
forms of one target-selection concern. A grouped optional object makes that
boundary explicit while the existing `repo_name` remains the fallback for
backward compatibility.

**Alternatives considered**:

- Two unrelated top-level variables: rejected because mutual exclusivity and
  omission behavior are less obvious.
- Replace `repo_name`: rejected because it would break existing consumers.
- Accept arbitrary upstream Runner fields: rejected because it would turn the
  wrapper into a broad pass-through.

## Decision: Support an existing authentication Secret

**Rationale**: The legacy chart supports `authSecret.create=false` and
`authSecret.name`. Referencing a separately managed Secret lets YAML
infrastructure avoid committing a GitHub token and keeps secret-material
lifecycle outside this module.

**Alternatives considered**:

- Token literal in YAML: rejected because it commits a credential and exposes it
  to more state/configuration surfaces.
- Create an ExternalSecret in this module: rejected because secret-store access
  is a separate privilege boundary and existing shared modules already own it.
- GitHub App fields: deferred because broadening all authentication modes is not
  required for the current common case.

## Decision: Reuse kubectl provider environment defaults

**Rationale**: Kubectl provider `~> 1.14` reads host, token, CA data, kubeconfig
path, and load-file behavior from `KUBE_*` environment variables. Replacing the
hardcoded path with the existing nullable module input preserves local consumers
while allowing a Terraform Cloud variable set to configure the provider.

**Alternatives considered**:

- Add host/token/CA module inputs: rejected because credentials belong to
  provider configuration, would widen the module interface, and would duplicate
  Terraform Cloud variable-set behavior.
- Remove the internal provider configuration immediately: rejected because it
  would make the existing `kubectl_config_path` input ineffective for historical
  consumers.

## Decision: Keep historical state addresses

**Rationale**: Existing consumers may already track `helm_release.test` and
`kubectl_manifest.pv_mongo_main[0]`. Keeping those labels for legacy mode avoids
an unnecessary state migration. New modes use a separate keyed resource.

**Alternatives considered**:

- Rename all resources for clarity: rejected because it creates avoidable
  destroy/recreate or moved-state work.
- Convert the historical runner resource to `for_each`: rejected because it
  changes its state address.

## Decision: Test with mock providers

**Rationale**: Terraform tests can inspect rendered manifest and Helm values
without cluster or GitHub credentials. This covers target selection and
validation deterministically and enables the module's Terraform Test matrix
entry.

**Alternatives considered**:

- Live cluster integration tests: deferred because credentials and controller
  installation would make repository CI expensive and environment-dependent.
- Validation only: rejected because it cannot prove rendered scope, names, or
  invalid combination behavior.
