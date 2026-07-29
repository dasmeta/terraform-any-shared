# Data Model: Shared Kubernetes Namespace Module

## Namespace Input

| Field | Required | Type | Meaning |
| --- | --- | --- | --- |
| `name` | yes | string | Stable Kubernetes namespace name. |
| `labels` | no | map(string) | Caller-owned organisational metadata. |
| `annotations` | no | map(string) | Caller-owned controller or operational metadata. |

## Output Contract

| Output | Meaning |
| --- | --- |
| `namespace_name` | Namespace name for Helm and Kubernetes consumers. |
| `namespace_id` | Provider resource identity. |
| `namespace_uid` | Kubernetes-assigned immutable identity. |
