# Quickstart: Optional Authentik ingress

```hcl
ingress = {
  enabled         = true
  hostname        = "auth.example.com"
  class_name      = "nginx"
  tls_secret_name = "auth-example-com-tls"
  cluster_issuer  = "letsencrypt-prod"
}
```

Create the corresponding DNS record separately, pointing at the cluster's
ingress controller. Do not enable an already-live hostname on a second
Authentik release until the intended cutover has been approved.
