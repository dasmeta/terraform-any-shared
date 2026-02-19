# Istio Gateway API Only Configuration

This example demonstrates how to configure Istio for **vertical routing only** (Gateway API ingress/egress) with **horizontal service mesh routing disabled**.

## What This Configuration Does

- ✅ Installs Istio with Gateway API CRDs support
- ✅ Disables automatic sidecar injection (no horizontal service mesh)
- ✅ Enables Istio Gateway API controller for vertical routing
- ✅ Uses Istio Gateway resources for traffic ingress/egress only

## Key Configuration Points

### 1. Disable Automatic Sidecar Injection

The critical setting is in `istiod.configs`:

```hcl
global = {
  proxy = {
    autoInject = "disabled"
  }
}
```

This prevents Istio from automatically injecting sidecars into pods, effectively disabling horizontal service mesh routing.

### 2. Enable Gateway API Support

Gateway API support is enabled by default in newer Istio versions, but explicitly set:

```hcl
pilot = {
  env = {
    PILOT_ENABLE_GATEWAY_API = "true"
    PILOT_ENABLE_GATEWAY_API_STATUS = "true"
  }
}
```

### 3. Gateway API Resources

After applying this configuration, you can use Kubernetes Gateway API resources:

- **GatewayClass**: Use `istio` as the gatewayClassName
- **Gateway**: Define ingress/egress gateways
- **HTTPRoute, GRPCRoute, TCPRoute, TLSRoute, UDPRoute**: Define routing rules

## Usage

1. Set up your Kubernetes context:
   ```bash
   export KUBECONFIG=/path/to/your/k8s.kubeconfig
   export KUBE_CONFIG_PATH=$KUBECONFIG
   ```

2. Apply the configuration:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

3. Verify Istio Gateway API is working:
   ```bash
   kubectl get gatewayclass
   kubectl get gateway -A
   ```

## Example Gateway API Resources

After Istio is installed, you can create Gateway API resources like:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: my-gateway
spec:
  gatewayClassName: istio
  listeners:
    - name: http
      port: 80
      protocol: HTTP
```

## Notes

- Pods will **NOT** have Istio sidecars injected automatically
- Traffic between services uses standard Kubernetes Service networking
- Only ingress/egress traffic goes through Istio Gateway
- This is ideal for using Istio as an advanced ingress controller with Gateway API
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.0 |
| <a name="requirement_http"></a> [http](#requirement\_http) | ~> 3.0 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | ~> 1.14 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_this"></a> [this](#module\_this) | ../.. | n/a |

## Resources

No resources.

## Inputs

No inputs.

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
