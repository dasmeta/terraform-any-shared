# Quickstart

## Historical consumer

1. Keep the existing runner name, repository, personal access token, and
   kubeconfig-path inputs.
2. Upgrade to the released module version after validation.
3. Confirm the plan retains one repository-scoped runner and the existing
   namespace.

## YAML and Terraform Cloud consumer

1. Create the GitHub authentication Secret through the approved external-secret
   workflow in the controller namespace; do not put its value in YAML.
2. Configure the runner module Setup with `github_auth_secret_name` and omit the
   personal access token.
3. Set `kubectl_config_path` to `null` and attach the Terraform Cloud variable set
   that already provides Kubernetes provider credentials.
4. Select either an explicit repository collection or one organization.
5. Use only a released module version in the infrastructure Setup.
6. Run `meta validate-yaml`, generate the Terraform Cloud workspace, and review
   the remote plan before apply.

## Module verification

From the module repository:

```bash
terraform fmt -check -recursive modules/github-actions-runner
terraform -chdir=modules/github-actions-runner init -backend=false
terraform -chdir=modules/github-actions-runner validate
terraform -chdir=modules/github-actions-runner test
```

No live GitHub token or Kubernetes cluster is required for the mock-provider
test suite.
