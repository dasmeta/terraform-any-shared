# Istio 1.32.0 defaults

Update `modules/istio` to the official 1.32.0 charts and document the supported upgrade path for existing installations.

- Default chart version: `1.30.3` → `1.32.0`.
- Default repository: `https://blob.istio.io/istio-release/charts`.
- Images continue to inherit chart defaults; explicit chart/image overrides retain precedence.
- Align module documentation and chart/image examples.
- Document separate 1.31.x and 1.32.0 applies for in-place upgrades from 1.30, including version overrides and rollout verification.
- Keep all code, documentation, and planning notes generic and suitable for public distribution.
- Leave Kiali, Gateway API CRDs, and module interfaces unchanged.
- Preparation only: no cluster apply, commit, or publication.
