# chart-direct-tgz-sources

This example points the Istio module at direct upstream Helm chart `.tgz` URLs instead of repository-backed chart names.

It is intended for Docker Desktop Kubernetes or another disposable test cluster.

The Terraform example uses chart archive URLs from the same public Helm chart sources that the module normally consumes through repository-backed chart names. This proves that the module can pass direct chart URLs while omitting `repository` and `version` on the matching Helm releases. The helper `http-echo` release intentionally stays repository-backed.

## Artifacts Used

- Istio base chart: `https://istio-release.storage.googleapis.com/charts/base-1.29.2.tgz`
- Istiod chart: `https://istio-release.storage.googleapis.com/charts/istiod-1.29.2.tgz`
- Optional Istio gateway chart: `https://istio-release.storage.googleapis.com/charts/gateway-1.29.2.tgz`
- Gateway API resources chart: `https://github.com/dasmeta/helm/releases/download/gateway-api-0.1.7/gateway-api-0.1.7.tgz`
- Optional Kiali operator chart: `https://kiali.org/helm-charts/kiali-operator-2.25.0.tgz`
- HTTP echo helper chart: repository `https://dasmeta.github.io/helm`, chart `base`, version `0.3.29`

## Docker Desktop Setup

```sh
export KUBECONFIG="${HOME}/.kube/config"
export KUBE_CONFIG_PATH="${KUBECONFIG}"
kubectl config use-context docker-desktop
```

## Run

```sh
terraform init -backend=false
terraform plan
```

To also install the optional Istio gateway chart:

```sh
terraform plan -var='enable_istio_gateway_chart=true'
```

To also install Kiali:

```sh
terraform plan -var='enable_kiali=true'
```
