# Opt-in Test retention

Provide exact unique engagement names. This example enables automatic token
bootstrap: after DefectDojo is ready, a hook Job uses the application's existing
account credentials to populate `example-defectdojo-retention` in
`example-security`, with key `api-key`, then Terraform deploys the CronJob.
The token inherits that account's privileges (usually administrator). It may
already be shared with CI; bootstrap reuses valid tokens and never rotates them.

For a dedicated account managed outside this module, omit `create = true` and
provision the referenced Secret yourself, for example through External Secrets.
That API user must have complete Test/import/finding visibility and Test deletion
rights in the selected engagements; partial finding visibility is unsafe.

Configure real ingress/database settings using the existing module inputs before
applying an installation. The bootstrap password must match the existing account
and token authentication must be enabled. Validation commands do not authenticate,
create tokens or delete data. Applying does enable bootstrap and retention.

```sh
terraform init
terraform plan -var='engagement_names=["backend","frontend"]'
```

Names are resolved to IDs through the API at every Job start. Missing or
ambiguous names abort before deletion. To cover every API-visible engagement,
replace the named selector with `all_engagements = true`; newly visible
engagements then enter scope automatically. Empty names never mean all. The
existing `engagement_ids` selector is also supported; selectors cannot be mixed.

Use only retired feature scopes. The worker preserves active findings,
protected branches/environments, tags/releases, ambiguous/legacy titles, recent
imports and recent Test modifications. API prechecks cannot atomically exclude
a concurrent reimport. Suspend cleanup while rerunning expired branches.

Kubernetes >=1.27 is required. Disabling retention prevents future schedules but
does not stop an already running Job; terminate it separately when immediate
cessation is required. Terraform rollback cannot restore deleted data.
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_defectdojo"></a> [defectdojo](#module\_defectdojo) | ../.. | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_engagement_names"></a> [engagement\_names](#input\_engagement\_names) | Exact unique names of engagements with retired feature Tests eligible for retention. | `set(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_helm_metadata"></a> [helm\_metadata](#output\_helm\_metadata) | Application release metadata; retention is a separate companion release. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
