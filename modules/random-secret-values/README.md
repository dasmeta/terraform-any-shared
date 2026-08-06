# Random secret values

Generates a named, sensitive credential payload for a dedicated secret-store
consumer. It does not create an AWS secret, Kubernetes Secret, database, or
application resource.

Use the `values` output as the `value` input of
`dasmeta/modules/aws//modules/secret`; keep that downstream output sensitive.
This preserves a single secret-store source of truth while avoiding plaintext
credentials in YAML and Git.

`static_values` is intended for non-generated metadata that must be in the same
payload. `aliases` permits another key to reuse one generated credential, such
as mapping a database password to an application configuration key.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.6 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_random"></a> [random](#provider\_random) | 3.9.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [random_password.this](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_aliases"></a> [aliases](#input\_aliases) | Optional destination-to-source key mappings. Each source must be a generated or static key; aliases cannot reference aliases. | `map(string)` | `{}` | no |
| <a name="input_generated_values"></a> [generated\_values](#input\_generated\_values) | Named random password policies. Each key becomes one generated sensitive value. | <pre>map(object({<br/>    length           = number<br/>    special          = optional(bool, true)<br/>    upper            = optional(bool, true)<br/>    lower            = optional(bool, true)<br/>    numeric          = optional(bool, true)<br/>    min_upper        = optional(number, 0)<br/>    min_lower        = optional(number, 0)<br/>    min_numeric      = optional(number, 0)<br/>    min_special      = optional(number, 0)<br/>    override_special = optional(string, null)<br/>  }))</pre> | n/a | yes |
| <a name="input_static_values"></a> [static\_values](#input\_static\_values) | Optional static values merged into the sensitive result map, such as a fixed database owner name. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_keys"></a> [keys](#output\_keys) | Non-sensitive sorted keys in the generated values map. |
| <a name="output_values"></a> [values](#output\_values) | Complete generated credential payload for a dedicated secret-store consumer. |
<!-- END_TF_DOCS -->
