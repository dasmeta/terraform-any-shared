# Data Model: Official GitHub ARC Runner Scale Sets

## Deployment Mode

| Field | Meaning | Rules |
|---|---|---|
| `deployment_mode` | Selected module behavior | `legacy` by default; `scale_set` opt-in. |

## Scale-Set Configuration

| Field | Meaning | Rules |
|---|---|---|
| `github_config_url` | One GitHub organization or repository scope | Required for `scale_set`; HTTPS GitHub URL. |
| `runner_scale_set_name` | Workflow runner label | Valid Kubernetes-compatible label. |
| `min_runners` | Idle runner baseline | Non-negative integer and no larger than maximum. |
| `max_runners` | Autoscaling limit | Non-negative integer and no less than minimum. |
| chart versions | Controller and scale-set release pins | Non-empty when supplied. |

## Authentication Source

| Field | Meaning | Rules |
|---|---|---|
| `github_auth_secret_name` | Existing Kubernetes Secret | Exactly one with token; module only references it. |
| `personal_access_token` | Sensitive GitHub API credential | Exactly one with Secret; never an output. |

## Relationships

- `scale_set` mode creates the controller release, then the scale-set release.
- The scale-set release uses one Authentication Source and one GitHub scope.
- A GitHub workflow uses the scale-set name to request an ephemeral runner.
