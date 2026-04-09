# akhq

Terraform wrapper around the official **[AKHQ](https://akhq.io/)** Helm chart (`https://akhq.io/`) to run the Kafka **admin UI** on Kubernetes.

This module intentionally stays narrow (similar philosophy to `modules/keycloak`):

- Helm deploys AKHQ; you bring **Kafka** (`bootstrap_servers` and optional TLS/SASL properties).
- UI login defaults to **HTTP basic auth** with secrets written to the chart-managed Kubernetes Secret (not the ConfigMap).
- Optional **Ingress** wiring for controllers such as ALB or nginx (annotations are consumer-owned).
- Optional **`existing_secrets`** if you fully manage `application-secrets.yml` yourself.

## Requirements

- `helm` and `kubernetes` providers configured at the root module.
- Network reachability from the cluster to your Kafka bootstrap endpoints.

## Baseline usage

```terraform
module "akhq" {
  source = "dasmeta/shared/any//modules/akhq"

  hostname = "akhq.example.com"

  security = {
    enabled             = true
    basic_auth_username = "admin"
    basic_auth_password = "change-me"
  }

  kafka = {
    bootstrap_servers = "kafka.example.internal:9092"
  }
}
```

## Ingress (e.g. ALB)

```terraform
module "akhq" {
  source = "dasmeta/shared/any//modules/akhq"

  hostname = "akhq.example.com"

  security = {
    enabled             = true
    basic_auth_username = "admin"
    basic_auth_password = "use-tfvars-or-secret-manager"
  }

  kafka = {
    bootstrap_servers = "kafka.example.internal:9092"
  }

  ingress = {
    enabled            = true
    ingress_class_name = "alb"
    annotations = {
      "alb.ingress.kubernetes.io/group.name"    = "example-ingress"
      "alb.ingress.kubernetes.io/scheme"      = "internal"
      "alb.ingress.kubernetes.io/target-type" = "ip"
    }
  }
}
```

## SASL / sensitive Kafka client properties

Put non-sensitive properties in `kafka.properties` and sensitive ones in `kafka_secret_properties` (merged into the Helm **Secret**).

**MSK SCRAM-SHA-512 (typical on `:9096`):** set `kafka.properties` to `security.protocol=SASL_SSL` and `sasl.mechanism=SCRAM-SHA-512`, then either:

- **`kafka_scram_username` + `kafka_scram_password`** — the module builds `sasl.jaas.config` (same pattern as Spring `SPRING_KAFKA_PROPERTIES_SASL_JAAS_CONFIG`), or
- **`kafka_secret_properties.sasl.jaas.config`** — store the full JAAS line in Terraform Cloud / Secrets Manager and pass it through (this map overrides duplicate keys from the SCRAM username/password helper).

**Versioning (DasMeta / Terraform Cloud):** after merging to GitHub, create a **git tag** your registry consumes (for example `modules/akhq/v0.2.0` or whatever `dasmeta/shared/any` maps to) and set `version:` in your values YAML to that tag.

## Existing application Secret

If you set `existing_secrets` to a Secret name, the chart uses that Secret for `application-secrets.yml` and this module does not render chart `secrets`. You must supply Micronaut JWT material, optional basic-auth, and Kafka secrets in that object yourself.

## Examples

See `examples/basic`.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.5 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | ~> 2.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | ~> 2.0 |
| <a name="provider_random"></a> [random](#provider\_random) | ~> 3.5 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.this](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_namespace_v1.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace_v1) | resource |
| [random_password.micronaut_jwt](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Version of the tchiotludo/akhq Helm chart (repo https://akhq.io/). | `string` | `"0.27.0"` | no |
| <a name="input_create_namespace"></a> [create\_namespace](#input\_create\_namespace) | Create the namespace with the Kubernetes provider before the Helm release. | `bool` | `true` | no |
| <a name="input_existing_secrets"></a> [existing\_secrets](#input\_existing\_secrets) | If set, chart uses this Secret name for application-secrets.yml instead of chart-created secrets (you manage content). | `string` | `null` | no |
| <a name="input_extra_configuration"></a> [extra\_configuration](#input\_extra\_configuration) | Merged into chart configuration (ConfigMap). Use for advanced AKHQ/micronaut settings; shallow merge at root keys. | `any` | `{}` | no |
| <a name="input_helm_timeout"></a> [helm\_timeout](#input\_helm\_timeout) | Helm wait timeout in seconds. | `number` | `600` | no |
| <a name="input_hostname"></a> [hostname](#input\_hostname) | Hostname for Ingress when ingress.enabled is true. | `string` | n/a | yes |
| <a name="input_ingress"></a> [ingress](#input\_ingress) | Ingress configuration for networking.k8s.io/Ingress (e.g. ALB, nginx). | <pre>object({<br/>    enabled            = optional(bool, true)<br/>    ingress_class_name = optional(string)<br/>    annotations        = optional(map(string), {})<br/>    path               = optional(string, "/")<br/>    path_type          = optional(string, "Prefix")<br/>    tls = optional(list(object({<br/>      secretName = string<br/>      hosts      = list(string)<br/>    })), [])<br/>  })</pre> | `{}` | no |
| <a name="input_kafka"></a> [kafka](#input\_kafka) | Kafka cluster connection (non-sensitive properties only; use kafka\_secret\_properties for SASL/SSL secrets). | <pre>object({<br/>    connection_name   = optional(string, "kafka")<br/>    bootstrap_servers = string<br/>    properties        = optional(map(string), {})<br/>  })</pre> | n/a | yes |
| <a name="input_kafka_scram_password"></a> [kafka\_scram\_password](#input\_kafka\_scram\_password) | Optional MSK SCRAM-SHA-512 password; used with kafka\_scram\_username. | `string` | `null` | no |
| <a name="input_kafka_scram_username"></a> [kafka\_scram\_username](#input\_kafka\_scram\_username) | Optional MSK SCRAM-SHA-512 username; combined with kafka\_scram\_password to set sasl.jaas.config. Omit if you pass the full line in kafka\_secret\_properties instead. | `string` | `null` | no |
| <a name="input_kafka_secret_properties"></a> [kafka\_secret\_properties](#input\_kafka\_secret\_properties) | Sensitive Kafka client properties merged into Helm secrets for the connection (e.g. sasl.jaas.config). Keys here override the same keys from kafka\_scram\_username/kafka\_scram\_password. | `map(string)` | `{}` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the Helm release. | `string` | `"akhq"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Kubernetes namespace for AKHQ. | `string` | `"akhq"` | no |
| <a name="input_network_policy_enabled"></a> [network\_policy\_enabled](#input\_network\_policy\_enabled) | Set chart networkPolicy.enabled. Disable if your cluster/network policies block AKHQ by default. | `bool` | `false` | no |
| <a name="input_pod_labels"></a> [pod\_labels](#input\_pod\_labels) | Extra pod labels passed to the chart. | `map(string)` | `{}` | no |
| <a name="input_replicas"></a> [replicas](#input\_replicas) | Deployment replica count (chart value replicaCount). | `number` | `1` | no |
| <a name="input_resources"></a> [resources](#input\_resources) | Container resources for the AKHQ pod. | <pre>object({<br/>    limits   = optional(map(string), {})<br/>    requests = optional(map(string), {})<br/>  })</pre> | `{}` | no |
| <a name="input_security"></a> [security](#input\_security) | AKHQ UI authentication. When enabled, basic\_auth\_password is required unless you use existing\_secrets for all secret material. basic\_auth\_password must be plaintext unless basic\_auth\_password\_prehashed is true (then supply SHA-256 hex as AKHQ expects). | <pre>object({<br/>    enabled                       = optional(bool, true)<br/>    basic_auth_username           = optional(string, "admin")<br/>    basic_auth_password           = optional(string)<br/>    basic_auth_password_prehashed = optional(bool, false)<br/>    basic_auth_groups             = optional(list(string), ["admin"])<br/>    micronaut_jwt_secret          = optional(string)<br/>  })</pre> | <pre>{<br/>  "enabled": true<br/>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_helm_metadata"></a> [helm\_metadata](#output\_helm\_metadata) | Helm release metadata. |
| <a name="output_ingress_hostnames"></a> [ingress\_hostnames](#output\_ingress\_hostnames) | Ingress hostnames when ingress is enabled. |
| <a name="output_release_chart_version"></a> [release\_chart\_version](#output\_release\_chart\_version) | Chart version applied. |
| <a name="output_release_name"></a> [release\_name](#output\_release\_name) | Helm release name. |
| <a name="output_release_namespace"></a> [release\_namespace](#output\_release\_namespace) | Kubernetes namespace of the release. |
| <a name="output_release_status"></a> [release\_status](#output\_release\_status) | Helm release status. |
<!-- END_TF_DOCS -->
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.5 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | ~> 2.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | ~> 2.0 |
| <a name="provider_random"></a> [random](#provider\_random) | ~> 3.5 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.this](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_namespace_v1.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace_v1) | resource |
| [random_password.micronaut_jwt](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Version of the tchiotludo/akhq Helm chart (repo https://akhq.io/). | `string` | `"0.27.0"` | no |
| <a name="input_create_namespace"></a> [create\_namespace](#input\_create\_namespace) | Create the namespace with the Kubernetes provider before the Helm release. | `bool` | `true` | no |
| <a name="input_existing_secrets"></a> [existing\_secrets](#input\_existing\_secrets) | If set, chart uses this Secret name for application-secrets.yml instead of chart-created secrets (you manage content). | `string` | `null` | no |
| <a name="input_extra_configuration"></a> [extra\_configuration](#input\_extra\_configuration) | Merged into chart configuration (ConfigMap). Use for advanced AKHQ/micronaut settings; shallow merge at root keys. | `any` | `{}` | no |
| <a name="input_helm_timeout"></a> [helm\_timeout](#input\_helm\_timeout) | Helm wait timeout in seconds. | `number` | `600` | no |
| <a name="input_hostname"></a> [hostname](#input\_hostname) | Hostname for Ingress when ingress.enabled is true. | `string` | n/a | yes |
| <a name="input_ingress"></a> [ingress](#input\_ingress) | Ingress configuration for networking.k8s.io/Ingress (e.g. ALB, nginx). | <pre>object({<br/>    enabled            = optional(bool, true)<br/>    ingress_class_name = optional(string)<br/>    annotations        = optional(map(string), {})<br/>    path               = optional(string, "/")<br/>    path_type          = optional(string, "Prefix")<br/>    tls = optional(list(object({<br/>      secretName = string<br/>      hosts      = list(string)<br/>    })), [])<br/>  })</pre> | `{}` | no |
| <a name="input_kafka"></a> [kafka](#input\_kafka) | Kafka cluster connection (non-sensitive properties only; use kafka\_secret\_properties for SASL/SSL secrets). | <pre>object({<br/>    connection_name   = optional(string, "kafka")<br/>    bootstrap_servers = string<br/>    properties        = optional(map(string), {})<br/>  })</pre> | n/a | yes |
| <a name="input_kafka_scram_password"></a> [kafka\_scram\_password](#input\_kafka\_scram\_password) | Optional MSK SCRAM-SHA-512 password; used with kafka\_scram\_username. | `string` | `null` | no |
| <a name="input_kafka_scram_username"></a> [kafka\_scram\_username](#input\_kafka\_scram\_username) | Optional MSK SCRAM-SHA-512 username; combined with kafka\_scram\_password to set sasl.jaas.config. Omit if you pass the full line in kafka\_secret\_properties instead. | `string` | `null` | no |
| <a name="input_kafka_secret_properties"></a> [kafka\_secret\_properties](#input\_kafka\_secret\_properties) | Sensitive Kafka client properties merged into Helm secrets for the connection (e.g. sasl.jaas.config). Keys here override the same keys from kafka\_scram\_username/kafka\_scram\_password. | `map(string)` | `{}` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the Helm release. | `string` | `"akhq"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Kubernetes namespace for AKHQ. | `string` | `"akhq"` | no |
| <a name="input_network_policy_enabled"></a> [network\_policy\_enabled](#input\_network\_policy\_enabled) | Set chart networkPolicy.enabled. Disable if your cluster/network policies block AKHQ by default. | `bool` | `false` | no |
| <a name="input_pod_labels"></a> [pod\_labels](#input\_pod\_labels) | Extra pod labels passed to the chart. | `map(string)` | `{}` | no |
| <a name="input_replicas"></a> [replicas](#input\_replicas) | Deployment replica count (chart value replicaCount). | `number` | `1` | no |
| <a name="input_resources"></a> [resources](#input\_resources) | Container resources for the AKHQ pod. | <pre>object({<br/>    limits   = optional(map(string), {})<br/>    requests = optional(map(string), {})<br/>  })</pre> | `{}` | no |
| <a name="input_security"></a> [security](#input\_security) | AKHQ UI authentication. When enabled, basic\_auth\_password is required unless you use existing\_secrets for all secret material. basic\_auth\_password must be plaintext unless basic\_auth\_password\_prehashed is true (then supply SHA-256 hex as AKHQ expects). | <pre>object({<br/>    enabled                       = optional(bool, true)<br/>    basic_auth_username           = optional(string, "admin")<br/>    basic_auth_password           = optional(string)<br/>    basic_auth_password_prehashed = optional(bool, false)<br/>    basic_auth_groups             = optional(list(string), ["admin"])<br/>    micronaut_jwt_secret          = optional(string)<br/>  })</pre> | <pre>{<br/>  "enabled": true<br/>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_helm_metadata"></a> [helm\_metadata](#output\_helm\_metadata) | Helm release metadata. |
| <a name="output_ingress_hostnames"></a> [ingress\_hostnames](#output\_ingress\_hostnames) | Ingress hostnames when ingress is enabled. |
| <a name="output_release_chart_version"></a> [release\_chart\_version](#output\_release\_chart\_version) | Chart version applied. |
| <a name="output_release_name"></a> [release\_name](#output\_release\_name) | Helm release name. |
| <a name="output_release_namespace"></a> [release\_namespace](#output\_release\_namespace) | Kubernetes namespace of the release. |
| <a name="output_release_status"></a> [release\_status](#output\_release\_status) | Helm release status. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
