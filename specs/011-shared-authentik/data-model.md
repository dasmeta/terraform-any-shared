# Data model: Shared Authentik deployment module

## Inputs

| Name | Type | Required | Notes |
|---|---|---:|---|
| `name` | string | no | Helm release/resource prefix; defaults to `authentik`. |
| `namespace` | string | yes | Existing Kubernetes namespace. |
| `chart_version` | string | no | Defaults to the reviewed official chart version. |
| `configuration_secret_name` | string | yes | Existing Secret with `AUTHENTIK_SECRET_KEY` and `AUTHENTIK_POSTGRESQL__PASSWORD`. |
| `database.host` | string | yes | External PostgreSQL endpoint. |
| `database.name` | string | yes | Existing database name. |
| `database.user` | string | yes | Existing database user. |
| `database.port` | number | no | PostgreSQL port; defaults to 5432. |

## Rendered chart contract

```text
postgresql.enabled                         = false
authentik.existingSecret.secretName         = configuration_secret_name
global.env AUTHENTIK_POSTGRESQL__*          = database
fullnameOverride                            = name
server.service.type                         = ClusterIP
server.service.servicePortHttp              = 80
```

## Outputs

| Name | Meaning |
|---|---|
| `release_name` | Helm release name. |
| `release_namespace` | Release namespace. |
| `release_status` | Helm-reported status. |
| `release_chart_version` | Applied chart version. |
| `server_service_name` | Internal server Service name. |
| `server_service_http_port` | Internal HTTP port (80). |
