## Minimal module setup
```
module "supabase" {
    source = "dasmeta/modules/google//modules/supabase"
    version = "0.3.7"

    DB_PASSWORD = "yXm8FfPLMEvhXaQH"
}
```

## Maximal module setup

```
module "supabase" {
  source = "dasmeta/modules/google//modules/supabase"
  version = "0.3.7"

  DB_PASSWORD = "yXm8FfPLMEvhXaQH"
  namespace = ""
  ANON_KEY = ""
  SERVICE_KEY = ""
  JWT_SECRET = ""
  SMTP_HOST = ""
  SMTP_ADMIN_EMAIL = ""
  SMTP_USER = ""
  SMTP_PASS = ""
  SMTP_SENDER_NAME = ""
}
```
<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.supabase](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ANON_KEY"></a> [ANON\_KEY](#input\_ANON\_KEY) | n/a | `string` | `"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlhdCI6MTY0MDMwMDQwMCwiZXhwIjoxNzk4MDY2ODAwfQ.JaEiRNdyxX3Pk6XupxauDazXeadLTgTHz5cV7joUrQE"` | no |
| <a name="input_DB_PASSWORD"></a> [DB\_PASSWORD](#input\_DB\_PASSWORD) | n/a | `string` | `"yXmwewewddjijdFfPLMEvhXaQH"` | no |
| <a name="input_JWT_SECRET"></a> [JWT\_SECRET](#input\_JWT\_SECRET) | n/a | `string` | `"your-super-secret-jwt-token-with-at-least-32-characters-long"` | no |
| <a name="input_SERVICE_KEY"></a> [SERVICE\_KEY](#input\_SERVICE\_KEY) | n/a | `string` | `"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoic2VydmljZV9yb2xlIiwiaWF0IjoxNjQwMzAwNDAwLCJleHAiOjE3OTgwNjY4MDB9.sUJPVrhMsSaLgizyCWIgNOIRmjavxDB4Lm3hzb4dC5U"` | no |
| <a name="input_SMTP_ADMIN_EMAIL"></a> [SMTP\_ADMIN\_EMAIL](#input\_SMTP\_ADMIN\_EMAIL) | n/a | `string` | `"admin@example.com"` | no |
| <a name="input_SMTP_HOST"></a> [SMTP\_HOST](#input\_SMTP\_HOST) | n/a | `string` | `"mail"` | no |
| <a name="input_SMTP_PASS"></a> [SMTP\_PASS](#input\_SMTP\_PASS) | n/a | `string` | `"fake_mail_password"` | no |
| <a name="input_SMTP_PORT"></a> [SMTP\_PORT](#input\_SMTP\_PORT) | n/a | `any` | `"2500"` | no |
| <a name="input_SMTP_SENDER_NAME"></a> [SMTP\_SENDER\_NAME](#input\_SMTP\_SENDER\_NAME) | n/a | `string` | `"fake_sender"` | no |
| <a name="input_SMTP_USER"></a> [SMTP\_USER](#input\_SMTP\_USER) | n/a | `string` | `"fake_mail_user"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | n/a | `string` | `"supabase"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->