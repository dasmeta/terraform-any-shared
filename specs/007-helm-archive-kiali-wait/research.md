# Research: Helm Archive Chart Sources and Kiali Apply Readiness

## Decision 1: Detect direct chart archives by HTTP(S) URL shape

**Decision**: Treat chart values matching `^https?://` as direct chart archive URLs.

**Rationale**: The change is specifically for direct `.tgz` links distributed over HTTP(S). This keeps detection deterministic, avoids a new input flag, and leaves existing repository-backed chart names unchanged.

**Alternatives considered**:

- Add a `chart_is_url` boolean for each chart field. Rejected because it duplicates information already present in the chart string and widens the interface unnecessarily.
- Detect only `.tgz` suffixes. Rejected because signed or redirected artifact URLs may include query strings, while the URL scheme is the provider-relevant distinction for repository/version handling.
- Treat all URLs including `oci://` as direct archives. Rejected because OCI chart handling may have different provider semantics and was not requested.

## Decision 2: Suppress repository and version for direct HTTP(S) chart URLs

**Decision**: For direct chart URLs, pass `null` for `repository` and `version` on the matching `helm_release`.

**Rationale**: Direct archive URLs are complete chart references. Passing repository/version alongside them can make Helm provider resolution ambiguous or fail because repository index lookup is not needed.

**Alternatives considered**:

- Preserve repository/version even when chart is a URL. Rejected because it keeps the failure mode the change is intended to remove.
- Require consumers to set repository/version to empty strings. Rejected because it creates fragile caller-side conventions and does not protect existing examples from accidental provider argument conflicts.

## Decision 3: Evaluate ingress gateway chart source per item

**Decision**: Apply URL detection independently for every `configs.gateway.ingress_gateways` item.

**Rationale**: The ingress gateway input is a list, and consumers may run multiple gateways with different chart sources during migration.

**Alternatives considered**:

- Add one global gateway chart URL flag. Rejected because it would not handle mixed gateway entries and would make list behavior less predictable.

## Decision 4: Make Kiali CR wait behavior unconditional when the CR is enabled

**Decision**: Set `wait = true` directly on `kubectl_manifest.this`.

**Rationale**: The Kiali CR exists to trigger an operator-managed deployment. Waiting for readiness improves apply ordering and avoids pushing readiness responsibility to consumers.

**Alternatives considered**:

- Add a new `configs.cr.wait` input. Rejected because the common case should wait and a new toggle would expose low-frequency behavior without a clear consumer need.
- Leave wait disabled and document manual retry behavior. Rejected because it preserves a known apply race.

## Validation Notes

- Run `terraform fmt` for `modules/istio`, `modules/kiali`, and the archive-backed example.
- Run `terraform validate` in `modules/istio/examples/chart-direct-tgz-sources` after provider initialization is available.
- Run `terraform validate` in `modules/kiali/examples/basic` and `modules/istio/examples/kiali-observability` to cover standalone and delegated Kiali paths.
