# SFTPGo SFTP Service Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an optional SFTP-only Kubernetes LoadBalancer Service to `modules/sftpgo`.

**Architecture:** Keep the upstream SFTPGo Helm chart service unchanged for in-cluster/UI routing. Add a separate `kubernetes_service_v1` owned by the wrapper module that selects the same SFTPGo pods and exposes only service port `22` to target port `sftp` (`2022` in the chart container). The feature is disabled by default and enabled through a grouped `sftp_service` object.

**Tech Stack:** Terraform `~> 1.3`, Helm provider `~> 2.0`, Kubernetes provider `~> 2.0`, SFTPGo Helm chart `0.45.0`.

---

## Chunk 1: SFTP Service Extension

### Task 1: Speckit Evidence

**Files:**
- Modify: `specs/009-sftpgo-module/spec.md`
- Modify: `specs/009-sftpgo-module/plan.md`
- Modify: `specs/009-sftpgo-module/tasks.md`

- [ ] Add a requirement for optional SFTP-only external TCP exposure.
- [ ] Record the decision to use a separate Kubernetes Service rather than changing the chart service.
- [ ] Add implementation and validation tasks for the new interface.

### Task 2: Failing Terraform Fixture

**Files:**
- Modify: `modules/sftpgo/tests/basic/main.tf`

- [ ] Add `sftp_service = { enabled = true, type = "LoadBalancer", annotations = {...} }` to the test module call.
- [ ] Run `terraform -chdir=modules/sftpgo/tests/basic validate`.
- [ ] Expected before implementation: failure because `sftp_service` is not an expected argument.

### Task 3: Module Implementation

**Files:**
- Modify: `modules/sftpgo/versions.tf`
- Modify: `modules/sftpgo/variables.tf`
- Create: `modules/sftpgo/sftp_service.tf`
- Modify: `modules/sftpgo/outputs.tf`

- [ ] Add the `hashicorp/kubernetes` provider constraint.
- [ ] Add grouped optional `sftp_service` input with `enabled`, `type`, `port`, `annotations`, and optional `load_balancer_source_ranges`.
- [ ] Create `kubernetes_service_v1.sftp` with `count = var.sftp_service.enabled ? 1 : 0`.
- [ ] Select pods by `app.kubernetes.io/name = "sftpgo"` and `app.kubernetes.io/instance = var.name`.
- [ ] Expose only TCP port `var.sftp_service.port` to `target_port = "sftp"`.
- [ ] Output service name and load balancer hostname when enabled.

### Task 4: Consumer Documentation

**Files:**
- Modify: `modules/sftpgo/README.md`
- Modify: `modules/sftpgo/examples/basic/1-example.tf`
- Modify: `modules/sftpgo/tests/basic/README.md`

- [ ] Document SFTP-only internal NLB usage with neutral hostnames/names.
- [ ] Keep the UI ingress example separate from the SFTP service example.
- [ ] Note that ALB Ingress is HTTP-only and not used for SFTP/SSH.

### Task 5: Verification

**Commands:**
- `terraform fmt -recursive modules/sftpgo`
- `terraform -chdir=modules/sftpgo init -backend=false`
- `terraform -chdir=modules/sftpgo validate`
- `terraform -chdir=modules/sftpgo/tests/basic init -backend=false`
- `terraform -chdir=modules/sftpgo/tests/basic validate`
- `terraform -chdir=modules/sftpgo/examples/basic init -backend=false`
- `terraform -chdir=modules/sftpgo/examples/basic validate`

- [ ] Run each command and inspect exit codes.
- [ ] Report any provider/network limitation explicitly.
