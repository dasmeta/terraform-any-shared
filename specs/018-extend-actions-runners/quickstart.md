# Quickstart

## Historical consumer

1. Keep the existing runner name, explicit repository, personal access token,
   and kubeconfig-path inputs. No default repository is selected.
2. Upgrade to the released module version after validation.
3. Confirm the plan retains one repository-scoped runner and the existing
   namespace.

## YAML and Terraform Cloud consumer

1. Create the GitHub authentication Secret through the approved external-secret
   workflow in the controller namespace; do not put its value in YAML.
2. Configure the runner module Setup with `github_auth_secret_name` and omit the
   personal access token.
3. Set `kubectl_config_path` to `null` and attach the Terraform Cloud variable set
   that already provides Kubernetes provider credentials. Null disables local
   kubeconfig loading so `KUBE_HOST`, `KUBE_TOKEN`, and related environment
   values are used directly.
4. Select either an explicit repository collection or one organization.
5. Pin `chart_version` to the reviewed legacy chart release.
6. Use only a released module version in the infrastructure Setup.
7. Run `meta validate-yaml`, generate the Terraform Cloud workspace, and review
   the remote plan before apply.

The retained internal kubectl provider prevents module-level `count`,
`for_each`, and `depends_on`. Use the grouped repository scope within one module
instance rather than repeating the module. Moving a live legacy `repo_name`
deployment to `runner_scope.repositories` replaces and re-registers its Runner.

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
