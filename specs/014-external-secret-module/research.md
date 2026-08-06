# Research: Shared ExternalSecret module

## Decisions

- **API**: Use `external-secrets.io/v1`, the supported ESO API.
- **Mapping**: Use explicit `spec.data` property mappings; do not expose broad `dataFrom` extraction.
- **Target type**: Always render `spec.target.template.type` so typed Kubernetes Secrets, including basic-auth, are possible without values in Terraform.
- **Lifecycle**: Use periodic `1h` refresh, Owner creation, and Retain deletion defaults as documented by ESO.
- **Fallback**: Use `kubectl_manifest`; no suitable wrapper exists in approved provider-maintained collections.

Sources: [ESO ExternalSecret API](https://external-secrets.io/latest/api/externalsecret/) and [ESO API specification](https://external-secrets.io/latest/api/spec/).
