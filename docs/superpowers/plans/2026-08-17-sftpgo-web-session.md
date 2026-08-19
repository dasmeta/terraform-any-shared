# SFTPGo Web Session Stability Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Preserve SFTPGo browser sessions across restarts and avoid short idle cookie expiry through an explicit module interface.

**Architecture:** Add a sensitive grouped `web_session` input to the existing opinionated SFTPGo wrapper. Render it into the upstream chart's `config.httpd` values while leaving token IP validation at SFTPGo's secure default unless the consumer opts in to another mode.

**Tech Stack:** Terraform `~> 1.3`, HashiCorp Helm provider, SFTPGo Helm chart, DasMeta YAML environment wrapper.

---

## Chunk 1: Module Contract

### Task 1: Add the failing fixture input

**Files:**
- Modify: `modules/sftpgo/tests/basic/main.tf`

- [ ] Add a `web_session` block to the test module call with a stable test passphrase and explicit cookie/token settings.
- [ ] Run `terraform -chdir=modules/sftpgo/tests/basic validate` and confirm it fails with an unsupported `web_session` argument.

### Task 2: Implement the input and Helm mapping

**Files:**
- Modify: `modules/sftpgo/variables.tf`
- Modify: `modules/sftpgo/locals.tf`

- [ ] Add the sensitive grouped `web_session` variable with optional `cookie_lifetime` and `token_validation` attributes and validation bounds.
- [ ] Add the `config.httpd` map to the chart values only when the session block is supplied.
- [ ] Keep `token_validation` default at `0`; use `signing_passphrase` as the stable JWT/CSRF signing input.
- [ ] Run the test fixture validation and confirm it passes.

## Chunk 2: Consumer Documentation and Environment

### Task 3: Update examples and README

**Files:**
- Modify: `modules/sftpgo/examples/basic/1-example.tf`
- Modify: `modules/sftpgo/examples/basic/README.md`
- Modify: `modules/sftpgo/tests/basic/README.md`
- Modify: `modules/sftpgo/README.md`

- [ ] Document the sensitive passphrase source, 720-minute cookie example, and the security tradeoff of `token_validation = 1`.
- [ ] Keep examples neutral and avoid real customer values.

### Task 4: Configure the dev consumer

**Files:**
- Modify: `/Users/vazgen/work/ben-energy/infrastructure_v2/1-environments/dev/sftpgo-new.yaml`

- [ ] Add `web_session` with the existing stable secret reference, `cookie_lifetime: 720`, and `token_validation: 0`.
- [ ] Preserve the existing SFTP LoadBalancer configuration and unrelated user changes.

## Chunk 3: Verification

### Task 5: Validate all Terraform artifacts

**Files:**
- No source changes.

- [ ] Run `terraform fmt -recursive modules/sftpgo`.
- [ ] Run module, example, and test fixture `terraform validate` commands.
- [ ] Run `git diff --check` and review only the intended files.
- [ ] Report that live Kubernetes verification remains pending until AWS credentials are refreshed.
