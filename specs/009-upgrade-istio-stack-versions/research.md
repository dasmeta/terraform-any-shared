# Research: Upgrade Istio Stack Tooling Versions

## Decision 1: Target Istio 1.30.3 as the fallback chart version
- **Decision**: Set the `modules/istio` fallback chart `version` default to `1.30.3`.
- **Rationale**: `1.30.3` is the latest stable Istio patch release, and the `base`/`istiod`/`gateway` chart archives are published on the istio-release chart storage.
- **Alternatives considered**:
  - Stay on `1.29.2`: rejected — does not satisfy the upgrade goal and misses patches.
  - Jump to a release candidate / dev build: rejected — operational instability risk.
  - Target `1.30.2` (the first pass): rejected — `1.30.3` is available and preferred.

## Decision 2: Target Gateway API CRDs v1.6.1
- **Decision**: Default `modules/gateway-api-crds` `version` to `v1.6.1` and ship `files/v1.6.1-standard-install.yaml`.
- **Rationale**: `v1.6.1` is the latest Gateway API release. Its standard-channel document set is identical to `v1.6.0` (a patch), so the `crdsList` derived from `v1.6.0`'s graduation applies unchanged.
- **Alternatives considered**:
  - `v1.6.0`: rejected — `v1.6.1` supersedes it with the same document set.
  - Stay on `v1.5.1`: rejected — misses the TCPRoute/UDPRoute GA graduation.

## Decision 3: Extend crdsList with tcproutes and udproutes
- **Decision**: Add `tcproutes` and `udproutes` CRD entries to the `crdsList` default (now 10 CRDs + 2 validating-admission-policy documents = 12 total).
- **Rationale**: TCPRoute and UDPRoute graduated to GA in the Gateway API v1.6 standard channel; the v1.6.1 `standard-install.yaml` contains their CRDs, so the applied list must cover all 12 documents or the two new CRDs would be silently skipped.
- **Verification**: The v1.6.1 manifest was confirmed to contain exactly 10 `CustomResourceDefinition` + 1 `ValidatingAdmissionPolicy` + 1 `ValidatingAdmissionPolicyBinding`; CRD and VAP `apiVersion`s are unchanged from v1.5.1, so the existing document-key paths for the retained entries stay valid.
- **Alternatives considered**:
  - Keep the 8-entry list: rejected — leaves two shipped CRDs unapplied.

## Decision 4: Target Kiali operator 2.29.0
- **Decision**: Default the Kiali operator chart version to `2.29.0` in `modules/kiali` and in the `modules/istio` kiali fallback.
- **Rationale**: `2.29.0` is the latest Kiali operator chart on `kiali.org/helm-charts`.
- **Alternatives considered**:
  - Stay on `2.25.0`: rejected — misses upstream fixes.
  - `2.28.0` (the first pass): rejected — `2.29.0` is available.

## Decision 5: Do NOT bump the dasmeta gateway-api chart version
- **Decision**: Leave the `gateway-api` resources chart at `0.1.7`.
- **Rationale**: The chart's templates already emit routes at `gateway.networking.k8s.io/v1` and did not change. Bumping the chart version with no content change would be misleading and, because the new version is not published to the release source, would break direct-`.tgz` consumers.
- **Alternatives considered**:
  - Bump to `0.1.8` to "signal" CRD alignment: rejected — no content change; version bumps must reflect real changes.

## Decision 6: Validate locally on docker-desktop via the direct-tgz example
- **Decision**: Verify by applying `modules/istio/examples/chart-direct-tgz-sources` against a local docker-desktop cluster and checking deployed versions + the test endpoint.
- **Rationale**: The example pulls charts directly from public `.tgz` URLs, making it the fastest faithful end-to-end check of the new versions without any additional chart hosting.
- **Alternatives considered**:
  - Static `terraform validate` only: rejected — does not exercise a real cluster upgrade.
  - Broader downstream environment rollout: rejected — a local cluster upgrade via the direct-tgz example is sufficient to prove the module change; environment rollout is outside module validation scope.
