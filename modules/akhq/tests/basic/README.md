# basic

Smoke configuration for the AKHQ module.

- **Validate only (no cluster):** `terraform init -backend=false` then `terraform validate`.
- **Apply to a real cluster:** use a kubeconfig that points at the cluster. After `meta exec <account> <env>`, run Terraform from the **same shell** so credentials exist.

Providers default to `~/.kube/config`. If your tool only sets `KUBECONFIG` to another file, pass:

```bash
terraform plan  -var="kubeconfig_path=${KUBECONFIG}"
terraform apply -var="kubeconfig_path=${KUBECONFIG}"
```

`main.tf` uses **placeholders** (hostname, Kafka brokers, cert ARN, `security.*` secrets) safe for git. For a real apply, either edit locally without committing or use a **gitignored** `terraform.tfvars` / `-var` for `kafka_scram_*` and adjust `main.tf` copies privately.

MSK **SCRAM**: set `kafka_scram_username` and `kafka_scram_password` via tfvars; **rotate** any credential that was ever committed.
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.5 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_akhq"></a> [akhq](#module\_akhq) | ../../ | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_kafka_scram_password"></a> [kafka\_scram\_password](#input\_kafka\_scram\_password) | MSK SCRAM-SHA-512 password. Never commit; use terraform.tfvars or TFC variables. | `string` | `""` | no |
| <a name="input_kafka_scram_username"></a> [kafka\_scram\_username](#input\_kafka\_scram\_username) | MSK SCRAM-SHA-512 username (passed through to the module). For real apply, set via terraform.tfvars (gitignored). | `string` | `""` | no |
| <a name="input_kubeconfig_path"></a> [kubeconfig\_path](#input\_kubeconfig\_path) | Path to kubeconfig. Leave empty to use ~/.kube/config. Set when your shell only sets KUBECONFIG to a non-default file (e.g. after meta exec). | `string` | `""` | no |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
