# Data model: Optional Authentik ingress

| Field | Required when enabled | Default | Meaning |
|---|---:|---|---|
| `enabled` | no | `false` | Creates the Authentik server ingress. |
| `hostname` | yes | empty | One public DNS hostname. |
| `tls_secret_name` | yes | empty | Same-namespace TLS Secret target. |
| `cluster_issuer` | yes | empty | cert-manager ClusterIssuer that obtains the certificate. |
| `annotations` | no | `{}` | Additional non-reserved ingress annotations. |

The module always uses the `nginx` IngressClass. Reserved annotations are `cert-manager.io/cluster-issuer` and
`nginx.ingress.kubernetes.io/force-ssl-redirect`; the module writes them after
additional annotations so they cannot be overridden.
