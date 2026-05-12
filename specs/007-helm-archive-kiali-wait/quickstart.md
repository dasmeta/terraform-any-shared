# Quickstart: Helm Archive Chart Sources and Kiali Apply Readiness

## 1. Confirm Speckit Package

```sh
SPECIFY_FEATURE=007-helm-archive-kiali-wait .specify/scripts/bash/check-prerequisites.sh --json --require-tasks --include-tasks
```

Expected result: JSON output identifies `specs/007-helm-archive-kiali-wait` and includes `research.md`, `data-model.md`, `contracts/`, `quickstart.md`, and `tasks.md`.

## 2. Review Implementation Scope

Expected module files:

- `modules/istio/main.tf`
- `modules/istio/variables.tf`
- `modules/istio/examples/chart-direct-tgz-sources/`
- `modules/kiali/main.tf`
- `modules/kiali/variables.tf`

Confirm no unrelated module source files are part of the change.

## 3. Validate Formatting

```sh
terraform fmt -check -recursive modules/istio modules/kiali
```

Expected result: no formatting diff is reported.

If formatting fails, run:

```sh
terraform fmt -recursive modules/istio modules/kiali
```

Then repeat the `-check` command.

## 4. Validate Affected Examples

When provider plugins are initialized or available in cache:

```sh
cd modules/istio/examples/chart-direct-tgz-sources
terraform init -backend=false
terraform validate
```

```sh
cd modules/kiali/examples/basic
terraform init -backend=false
terraform validate
```

```sh
cd modules/istio/examples/kiali-observability
terraform init -backend=false
terraform validate
```

Expected result: all validates pass.

## 5. Review Runtime Artifacts

Before staging, confirm generated Terraform runtime artifacts are not committed:

```sh
git status --short --ignored modules/istio/examples/chart-direct-tgz-sources
```

Expected result: only source files intended for the example are staged or shown as normal untracked files. `.terraform/`, `.terraform.lock.hcl`, `terraform.tfstate`, and `terraform.tfstate.backup` remain ignored.

## 6. Consumer Notes

- Repository-backed chart names continue to use `repository` and `version`.
- HTTP(S) chart archive URLs use the chart URL directly and suppress repository/version at the Helm resource.
- Kiali CR creation waits for readiness whenever the Kiali CR resource is enabled.
