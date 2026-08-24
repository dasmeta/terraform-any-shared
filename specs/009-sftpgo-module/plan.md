# Implementation Plan: SFTPGo Terraform Module

**Branch**: `009-sftpgo-module` | **Date**: 2026-07-03 | **Spec**: [spec.md](spec.md)  
**Input**: Feature specification from `specs/009-sftpgo-module/spec.md`

## Summary

Create `modules/sftpgo`, an opinionated Terraform wrapper around the upstream SFTPGo Helm chart. The module deploys SFTPGo into Kubernetes with required S3-backed bootstrap user storage, sensitive Terraform variable secrets for admin/user/S3 credentials, namespace support, persistence, UI ingress, resources, example usage, tests, and README documentation.

The module will use `helm_release` directly rather than wrapping the existing generic `service` module because the bootstrap sidecar and S3/user value generation are module-specific behavior. The interface stays narrow and grouped around the common deployment path instead of exposing the full Helm chart surface.

2026-08-17 extension: add optional SFTP-only external TCP exposure by creating a separate Kubernetes Service selected to the SFTPGo pods. This keeps the upstream chart's shared Service as `ClusterIP` for HTTP/UI and telemetry paths while allowing consumers to publish only SFTP through an internal network load balancer.

2026-08-17 extension: add an optional grouped `web_session` input that maps a
stable signing passphrase and explicit cookie/token settings to `config.httpd`.
The passphrase is supplied by the consumer as a sensitive value; no new secret
workspace or automatic secret resource is introduced in this change.

## Technical Context

**Terraform/OpenTofu Version**: Terraform `~> 1.3`  
**Providers / Upstream Modules**: HashiCorp Helm provider `~> 2.0`; HashiCorp Kubernetes provider `~> 2.0` for the optional SFTP Service; upstream SFTPGo Helm chart (`oci://ghcr.io/sftpgo/helm-charts`, chart `sftpgo`)
**Target Module Path**: `modules/sftpgo`  
**Examples / Tests in Scope**: `modules/sftpgo/examples/basic`, `modules/sftpgo/tests/basic`  
**Automation Gates**: `terraform fmt`, `terraform init -backend=false`, `terraform validate`; terraform-docs compatible README block when tooling is available  
**Target Platform**: Existing Kubernetes cluster reachable through Helm provider; S3-compatible object storage credentials supplied by the consumer  
**Constraints**: Preserve opinionated wrapper shape; no customer names, hostnames, paths, or secrets; no broad Helm values passthrough for low-frequency options; sensitive inputs must be marked sensitive  
**Session constraint**: Keep SFTPGo's `token_validation = 0` default unless a consumer explicitly opts into IP-independent validation.
**Scale/Scope**: One new module plus aligned example, test, README, and Speckit evidence

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] Change stays within one coherent module responsibility and the current repository scope.
- [x] Consumer interface remains opinionated; any interface widening is explicitly documented and approved.
- [x] `README.md`, `examples/`, and `tests/` updates are listed for every behavior or interface change.
- [x] `versions.tf` or `version.tf` and `providers.tf` impacts are reviewed and made explicit when compatibility changes.
- [x] Breaking changes, weakened defaults, or standards conflicts are recorded with approval status before implementation.

## Project Structure

### Documentation (this feature)

```text
specs/009-sftpgo-module/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── module-interface.md
├── checklists/
│   └── requirements.md
└── tasks.md
```

### Source Code (repository root)

```text
modules/sftpgo/
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
├── locals.tf
├── README.md
├── examples/
│   └── basic/
│       ├── 0-setup.tf
│       ├── 1-example.tf
│       └── README.md
└── tests/
    └── basic/
        ├── providers.tf
        ├── main.tf
        └── README.md
```

**Structure Decision**: Keep `required_providers` in `versions.tf`, matching most Helm-based modules in this repository. Do not create `providers.tf` in the module unless provider configuration is needed, which it is not for this wrapper.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| None | N/A | N/A |

## Phase 0 Research Summary

See [research.md](research.md).

Key decisions:

- Use direct `helm_release` against the SFTPGo chart as the upstream baseline.
- Use grouped object variables for S3 storage, bootstrap users, persistence, ingress, resources, and deployment behavior.
- Generate bootstrap sidecar configuration in locals so consumers do not copy scripting into each environment.
- Keep `extra_values` as a constrained advanced escape hatch merged last, while documenting that it is not the primary interface.
- For SFTP TCP exposure, create a separate `kubernetes_service_v1` instead of changing the chart Service to `LoadBalancer`, because the chart Service contains SFTP, HTTP, and telemetry ports.
- For WebUI session stability, expose only the three commonly operated `httpd` settings through a grouped input instead of forwarding all SFTPGo HTTP configuration.

## Phase 1 Design Summary

See [data-model.md](data-model.md), [contracts/module-interface.md](contracts/module-interface.md), and [quickstart.md](quickstart.md).

Post-design constitution check:

- [x] Scope remains `modules/sftpgo` plus aligned examples/tests/docs.
- [x] Interface remains grouped and opinionated; no broad chart surface is copied.
- [x] README, examples, and tests are included in tasks.
- [x] Provider expectations are explicit in `versions.tf`.
- [x] No breaking change exists because the module is new.
- [x] 2026-08-17 SFTP Service extension is backward-compatible and disabled by default.
- [x] 2026-08-17 Web session extension is opt-in, keeps the existing token validation default, and requires an explicit sensitive passphrase when enabled.
