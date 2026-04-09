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
