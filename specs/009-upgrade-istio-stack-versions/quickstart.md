# Quickstart: Implement Plan 009

## 1) Confirm workspace state
1. Ensure branch is `009-upgrade-istio-stack-versions`.
2. Ensure feature artifacts exist under `specs/009-upgrade-istio-stack-versions/`.
3. Baseline defaults before change:
   - `modules/istio`: fallback `chart.version` was `1.29.2`; kiali operator fallback `2.25.0`
   - `modules/gateway-api-crds`: default `version` was `v1.5.1` (8-CRD `crdsList`)
   - `modules/kiali`: `chart_version` was `2.25.0`

## 2) Update Gateway API CRD module
1. Download the official manifest to `modules/gateway-api-crds/files/v1.6.1-standard-install.yaml`
   from `https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.6.1/standard-install.yaml`.
2. Set default `version` to `v1.6.1` in `modules/gateway-api-crds/variables.tf`.
3. Add `tcproutes` and `udproutes` CRD entries to the `crdsList` default (now 12 documents total).
4. Retain `files/v1.5.1-standard-install.yaml` for rollback.

## 3) Update Istio module
1. Set fallback `chart.version` default to `1.30.3` in `modules/istio/variables.tf`.
2. Set the kiali operator fallback `chart_version` default to `2.29.0` in `modules/istio/variables.tf`.
3. Leave the gateway-api resources chart fallback at `0.1.7` (unchanged content).

## 4) Update Kiali module
1. Set `chart_version` default to `2.29.0` in `modules/kiali/variables.tf`.

## 5) Update the local verification example
1. In `modules/istio/examples/chart-direct-tgz-sources/1-example.tf`, set
   `istio_version = "1.30.3"` and `kiali_chart_version = "2.29.0"`.
2. Keep `gateway_api_chart_version = "0.1.7"` (published, unchanged).

## 6) Validate locally on docker-desktop
1. Point kube at docker-desktop:
   - `export KUBECONFIG=~/.kube/config KUBE_CONFIG_PATH=~/.kube/config`
   - `kubectl config use-context docker-desktop`
2. Plan and apply the example:
   - `cd modules/istio/examples/chart-direct-tgz-sources`
   - `terraform init && terraform plan`   # expect additions (new CRDs) + in-place updates, 0 destroys
   - `terraform apply -auto-approve`
3. Verify deployed versions:
   - `kubectl -n istio-system get deploy istiod -o jsonpath='{.spec.template.spec.containers[0].image}'` -> `...:1.30.3`
   - `kubectl get crd gateways.gateway.networking.k8s.io -o jsonpath='{.metadata.annotations.gateway\.networking\.k8s\.io/bundle-version}'` -> `v1.6.1`
   - `kubectl get crd tcproutes.gateway.networking.k8s.io udproutes.gateway.networking.k8s.io`  # both present
4. Verify the test endpoint:
   - `curl http://http-echo-chart-direct-tgz-sources.localhost/ping`

## 7) Run repository automation gates
1. `terraform fmt -recursive modules/istio modules/gateway-api-crds modules/kiali`
2. `pre-commit run terraform_fmt --all-files`
3. `pre-commit run terraform_docs --all-files`

## 8) Downstream compatibility summary
- Defaults-only upgrade; no interface changes. Consumers who pin versions are unaffected.
- In-place upgrade path verified (no destroys). No migration steps required for normal use.
