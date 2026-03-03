# Gateway API with Wildcard Domain and TLS (AWS EKS - External and Internal)

This example demonstrates how to configure Istio with Gateway API for a wildcard domain (`*.devops.dasmeta.com`) with both HTTP and HTTPS listeners on AWS EKS, supporting both external (internet-facing) and internal LoadBalancers.

## Features

- **Wildcard Domain**: `*.devops.dasmeta.com` - supports all subdomains under `devops.dasmeta.com`
- **Dual Gateway Setup**:
  - **External Gateway** (`main`): Internet-facing AWS Network Load Balancer for public access
  - **Internal Gateway** (`main-internal`): Internal AWS Network Load Balancer for VPC-only access
- **HTTP Listener**: Port 80 for HTTP traffic on both Gateways
- **HTTPS Listener**: Port 443 with TLS certificate managed by cert-manager on both Gateways
- **Automatic HTTP to HTTPS Redirect**: HTTPRoute resources automatically redirect all HTTP traffic to HTTPS (301 redirect)
- **Certificate Management**: Uses cert-manager with `letsencrypt-prod` ClusterIssuer for automatic certificate provisioning
- **Shared Certificate**: Both Gateways use the same TLS certificate Secret

## Prerequisites

1. **Istio** installed and running (via this module)
2. **cert-manager** installed in the cluster (v1.8+ required for Gateway API support)
3. **ClusterIssuer** named `letsencrypt-prod` configured in cert-manager

### ClusterIssuer Configuration for Gateway API

**IMPORTANT**: For HTTP01 challenges to work with Gateway API, the ClusterIssuer must be configured to use Gateway API instead of the default Ingress resources.

The ClusterIssuer needs to specify `gatewayHTTPRoute` in the HTTP01 solver configuration:

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
      - http01:
          gatewayHTTPRoute:
            parentRefs:
              - name: main
                namespace: istio-system
                kind: Gateway
                group: gateway.networking.k8s.io
```

**Key Configuration:**
- `gatewayHTTPRoute`: Tells cert-manager to create HTTPRoute resources instead of Ingress
- `parentRefs`: References the Gateway that cert-manager should use for HTTP01 challenges
  - `name`: Gateway name (use `main` for external Gateway - HTTP01 requires internet access)
  - `namespace`: Gateway namespace (typically `istio-system`)
  - `kind`: Must be `Gateway`
  - `group`: Must be `gateway.networking.k8s.io`

**Important for Dual Gateway Setup:**
- For HTTP01 challenges, reference the **external Gateway** (`main`) since Let's Encrypt needs internet access
- Both Gateways can use the same certificate Secret once it's created
- The internal Gateway (`main-internal`) will automatically use the certificate from the Secret

**Without this configuration**, cert-manager will default to creating Ingress resources, which won't work with Gateway API.

## Configuration

### External Gateway (`main`)
- Gateway name: `main`
- Gateway class: `istio`
- Namespace: `istio-system` (default)
- HTTP listener on port 80
- HTTPS listener on port 443 with TLS configuration pointing to cert-manager
- AWS NLB: Internet-facing Network Load Balancer
  - `service.beta.kubernetes.io/aws-load-balancer-scheme: "internet-facing"`
  - `service.beta.kubernetes.io/aws-load-balancer-type: "nlb"`
  - `service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "ip"`

### Internal Gateway (`main-internal`)
- Gateway name: `main-internal`
- Gateway class: `istio`
- Namespace: `istio-system` (default)
- HTTP listener on port 80
- HTTPS listener on port 443 with TLS configuration pointing to cert-manager
- AWS NLB: Internal Network Load Balancer (VPC-only access)
  - `service.beta.kubernetes.io/aws-load-balancer-scheme: "internal"`
  - `service.beta.kubernetes.io/aws-load-balancer-type: "nlb"`
  - `service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "ip"`

**Shared Certificate**: Both Gateways reference the same certificate Secret (`wildcard-devops-dasmeta-com-tls`), allowing them to serve the same domains with the same TLS certificate.

### HTTP to HTTPS Redirect

The example includes HTTPRoute resources that automatically redirect all HTTP traffic to HTTPS:

- **External Gateway Redirect**: `http-to-https-redirect-external` - redirects HTTP traffic on the external Gateway
- **Internal Gateway Redirect**: `http-to-https-redirect-internal` - redirects HTTP traffic on the internal Gateway

Both redirects:
- Match all hostnames: `*.devops.dasmeta.com`
- Reference the HTTP listener (`sectionName: "http-80"`) on their respective Gateways
- Use a 301 (Permanent Redirect) status code
- Redirect to HTTPS scheme

**Important Notes:**
- The redirects do **not** interfere with HTTP01 ACME challenges because:
  - cert-manager creates HTTPRoutes with specific path matches (`/.well-known/acme-challenge/*`)
  - Gateway API matches the most specific route first
  - cert-manager's HTTPRoutes will take precedence over the redirect for ACME challenge paths
- The HTTP listener (port 80) is still required for:
  - HTTP01 ACME challenges (if using HTTP01 resolver)
  - Initial HTTP requests that will be redirected to HTTPS

## Certificate Management

The HTTPS listener uses cert-manager to automatically provision and renew TLS certificates:
- Certificate name: `wildcard-devops-dasmeta-com-tls`
- ClusterIssuer: `letsencrypt-prod`
- DNS names: `*.devops.dasmeta.com`, `devops.dasmeta.com`

### How Gateway API Interacts with Certificates

**Important**: The Gateway API Gateway resource **only reads** the TLS certificate Secret - it does **not modify** it.

- **Existing Secrets**: If a Secret with the certificate already exists, the Gateway will use it without modification
- **Secret Management**: The Secret is managed entirely by cert-manager (via the Certificate resource)
- **Gateway Role**: The Gateway simply references the Secret via `certificateRefs` and reads the certificate data from it

### Certificate Rotation

Certificate rotation is handled **entirely by cert-manager** - Gateway API is **not involved** in the rotation process.

**How it works:**
1. **Initial Provisioning**: cert-manager creates the Certificate resource, which triggers the `letsencrypt-prod` ClusterIssuer
2. **Challenge Validation**: The ClusterIssuer uses either DNS01 or HTTP01 resolver to prove domain ownership:

   **DNS01 Challenge** (e.g., Route53, Cloudflare):
   - cert-manager creates DNS TXT records to prove domain ownership
   - No Gateway involvement required
   - Works for wildcard domains (`*.devops.dasmeta.com`)

   **HTTP01 Challenge**:
   - **Requires**: ClusterIssuer must be configured with `gatewayHTTPRoute` in the HTTP01 solver (see Prerequisites above)
   - cert-manager creates temporary HTTPRoute resources to serve challenge files
   - Challenge files are served at `http://<domain>/.well-known/acme-challenge/<token>`
   - **Requires**: Gateway must have an HTTP listener on port 80 (already configured in this example)
   - cert-manager automatically creates HTTPRoutes that route `/.well-known/acme-challenge/*` to cert-manager's solver service
   - The HTTPRoutes reference the Gateway via `parentRefs` (configured in ClusterIssuer)
   - The Gateway routes these HTTPRoutes normally - no special configuration needed
   - **Note**: HTTP01 does NOT work for wildcard domains - only exact domain matches

3. **Automatic Renewal**: cert-manager automatically monitors certificate expiration and renews certificates before they expire (typically 30 days before expiration)
4. **Secret Updates**: When cert-manager renews a certificate, it updates the Secret with the new certificate data
5. **Gateway Pickup**: The Gateway automatically picks up the new certificate from the updated Secret (no Gateway modification needed)

**Gateway API's Role**: The Gateway is a passive consumer of the Secret. It:
- Reads the certificate from the Secret when it starts
- Automatically reloads the certificate when the Secret is updated (Istio/Envoy watches the Secret)
- Does not participate in certificate creation, validation, or rotation
- For HTTP01: Routes HTTP traffic normally, including temporary challenge HTTPRoutes created by cert-manager

## Usage

After applying this configuration:
1. **Ensure ClusterIssuer is configured for Gateway API** (if using HTTP01):
   - The ClusterIssuer must have `gatewayHTTPRoute` configured in the HTTP01 solver
   - See "ClusterIssuer Configuration for Gateway API" section above
2. cert-manager will automatically create a Certificate resource
3. The Certificate will be validated by the `letsencrypt-prod` ClusterIssuer:
   - **DNS01**: cert-manager creates DNS TXT records (no Gateway involvement)
   - **HTTP01**: cert-manager creates temporary HTTPRoutes for `/.well-known/acme-challenge/*` (Gateway routes them normally)
4. Once validated, the certificate will be stored in the Secret `wildcard-devops-dasmeta-com-tls`
5. The Gateway will read the certificate from the Secret and use it for TLS termination
6. HTTPS traffic will be encrypted using the Let's Encrypt certificate
7. cert-manager will automatically renew the certificate before expiration (no Gateway changes needed)

**Important Notes:**
- **Wildcard domains** (`*.devops.dasmeta.com`) require **DNS01** resolver - HTTP01 does not support wildcards
- **HTTP01** requires:
  - Gateway to have an HTTP listener on port 80 (already configured)
  - ClusterIssuer configured with `gatewayHTTPRoute` in HTTP01 solver (see Prerequisites)
- For HTTP01, cert-manager automatically creates temporary HTTPRoutes - you don't need to create them manually
- The Gateway doesn't need special configuration for HTTP01 - it just routes HTTP traffic normally
- **Without `gatewayHTTPRoute` configuration**, cert-manager will default to creating Ingress resources, which won't work with Gateway API

## Example HTTPRoute

You can create HTTPRoute resources in any namespace that reference either Gateway:

### External Gateway Example

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: my-app-external
  namespace: my-namespace
spec:
  parentRefs:
    - name: main
      namespace: istio-system
  hostnames:
    - my-app.devops.dasmeta.com
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /
      backendRefs:
        - name: my-app-service
          port: 80
```

### Internal Gateway Example

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: my-app-internal
  namespace: my-namespace
spec:
  parentRefs:
    - name: main-internal
      namespace: istio-system
  hostnames:
    - my-app.devops.dasmeta.com
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /
      backendRefs:
        - name: my-app-service
          port: 80
```

**Note**: You can create HTTPRoutes that reference both Gateways if you want the same service accessible via both external and internal LoadBalancers.
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.0 |
| <a name="requirement_http"></a> [http](#requirement\_http) | ~> 3.0 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | ~> 1.14 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_kubectl"></a> [kubectl](#provider\_kubectl) | ~> 1.14 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_this"></a> [this](#module\_this) | ../.. | n/a |

## Resources

| Name | Type |
|------|------|
| [kubectl_manifest.wildcard_certificate](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_domain"></a> [domain](#input\_domain) | Domain name for DNS zones and Gateway API configuration | `string` | `"istio.devops.dasmeta.com"` | no |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
