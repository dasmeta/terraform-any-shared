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

## 2026-09-30 implementation plan: Trusted HTTP proxy

Goal: implement the user-approved option A in the existing SFTPGo wrapper.

Baseline: Helm chart 0.45.0; SFTPGo v2.7.1 HTTP defaults verified in upstream sftpgo.json. Current `web_session_values` only populates session fields; top-level extra_values is a shallow replacement. Existing provider-based resources remain appropriate; no new module/provider sourcing or scratch-template fallback is needed. Shared governance comes from the constitution skill references and this repository's .specify/memory/constitution.md.

Design: add `web_proxy` as a nullable object containing three proxy-specific fields. Render a single HTTP binding on 8080 with WebAdmin, WebClient and REST API enabled, matching the upstream supported baseline. Combine this binding with session fields in `config.httpd`; omit httpd entirely when neither input is set. Preserve top-level extra_values precedence instead of introducing an unrelated deep-merge contract change.

Files: variables.tf (input and validation), locals.tf (HTTP assembly), README.md (guidance and both existing generated tables), examples/basic/1-example.tf and README.md, tests/basic/main.tf and README.md, tests/web_proxy.tftest.hcl, specs/009-sftpgo-module artifacts. No outputs, provider constraints, service resources or CI workflows change. Keep established file layout; Terraform mock tests require Terraform >=1.7 only for the test runner, while module compatibility remains ~>1.3.

Modern capabilities: supported; this is existing SFTPGo HTTP configuration through the existing Helm provider values field, not a new provider capability. Sources: https://github.com/drakkan/sftpgo/blob/v2.7.1/sftpgo.json and https://docs.sftpgo.com/latest/config-file/.

Compatibility/approval: input defaults null, no breaking change or weakened default. User approved the narrow interface addition with 'давай сделаем это' after option A and its module changes were explained. Source edits are authorized; no live apply, release publication, or invented registry version is part of local verification. Prepare a separate prod-consumer patch once interface is tested; its release version must be an actually published version.

Checks: write/run a failing Terraform mocked plan test before implementation; run positive and negative input tests; terraform fmt and validate module/example/basic test; existing Ruby regression tests; helm template against pinned chart; git diff --check. Assert stable secret/session fields, enabled HTTP interfaces, unrelated generated config and ingress values. Record actual results below. Gate coverage uses this existing spec/plan/tasks package naming modules/sftpgo.

### Verification evidence (2026-09-30)

- RED: provider-mocked test failed before implementation with undeclared web_proxy and missing HTTP bindings. Sandbox blocked provider IPC; tests succeeded in starting outside sandbox.
- GREEN: `terraform test -filter=tests/web_proxy.tftest.hcl -no-color`: 12 passed, 0 failed. Includes explicit null trust list/entry rejection.
- `terraform validate` succeeded for module, examples/basic and tests/basic.
- Existing Ruby bootstrap preservation and service stability checks passed.
- `python3 tests/render_web_proxy_test.py /tmp/sftpgo-0.45.0.tgz` passed using real Terraform locals and upstream Helm chart 0.45.0, digest sha256:e28fdfafb1655d179eb77620b21f17ac9e67d0c7ac10463417716b5ad54c1aa0. ConfigMap and Deployment retain session values, HTTP interfaces, bootstrap sidecar and port.
- Formatting and git diff checks passed; both existing README generated blocks refreshed.
- Independent spec and implementation review found no blocking issues. SFTPGo v2.7.1 initializes the default HTTP binding before unmarshalling; omitted baseline fields remain, so copying the entire upstream binding is unnecessary.
- Prepared `/tmp/sftpgo-prod-web-proxy.patch` containing only new non-secret proxy settings. Proposed YAML parses, keeps token_validation 0, and `git apply --check --unidiff-zero` passes in the consumer repository. The consumer file remains unchanged until a module release containing this input is published and selected.
- No commit, release, infrastructure apply or runtime session test performed. Runtime acceptance remains: confirm network trust restrictions, deploy in dev with its own proxy CIDRs, verify effective client IP and no logout across proxy connections, then deploy prod.

## 2026-09-30 implementation plan: SFTP external traffic policy

Implement the user-approved additive field in the existing sftp_service object. Default Cluster preserves the Kubernetes default used today. Map Local/Cluster to kubernetes_service_v1.sftp.spec.external_traffic_policy only for LoadBalancer/NodePort; null for ClusterIP, with validation rejecting Local/ClusterIP. Existing direct Service resource remains the narrow SFTP-only wrapper baseline, so no new upstream module or template sourcing is applicable. Shared governance remains the constitution skill and repository constitution; no conflicts.

Modern capabilities: supported, existing nondeprecated Kubernetes Service field, no provider version increase required. References: https://kubernetes.io/docs/tasks/access-application-cluster/create-external-load-balancer/ and https://kubernetes-sigs.github.io/aws-load-balancer-controller/latest/guide/service/annotations/. Keep Terraform ~>1.3 and Kubernetes ~>2.0. Local mock test runner remains Terraform >=1.7.

Files: variables.tf, sftp_service.tf, README.md, examples/basic/1-example.tf and README.md, tests/basic/main.tf and README.md, tests/sftp_service.tftest.hcl, existing specs/009-sftpgo-module artifacts. Keep existing layout, generated README tables and previous Issue 1 changes. No CI, outputs or versions.tf changes.

Tests first: add a Local plan assertion and observe failure before implementation; cover default/explicit Cluster, Local LoadBalancer and NodePort, valid ClusterIP, invalid policy, invalid ClusterIP/Local and disabled Service. Verify existing class/source ranges/selector/port and annotations survive. Run all mocked tests, validate module/example/fixture, Ruby regressions, fmt/diff checks.

Consumer preparation: make a non-secret patch for the supplied prod YAML adding Local and `service.beta.kubernetes.io/aws-load-balancer-attributes: load_balancing.cross_zone.enabled=true`, preserving existing annotations. Local uses controller-managed HTTP health checks on healthCheckNodePort; verify health target transition, backend SG reachability and real source IP after deployment. Cross-zone routing does not add replicas or AZ resilience. No live apply or release is authorized by this implementation step; select an actually published new module version before applying the patch.

### SFTP traffic policy verification evidence (2026-09-30)

- Before implementation the Local assertion failed because the resource did not set the policy and its computed value was unknown during plan.
- After implementation, `terraform test -no-color`: 20 passed, 0 failed (8 Service cases plus all 12 Issue 1 cases). ClusterIP uses a mocked apply to prove its omitted computed policy resolves to the mock default; no real providers or cluster actions run.
- Module, examples/basic and tests/basic all passed Terraform validation. Existing Ruby service/bootstrap regression checks passed. Terraform formatting and git diff checks passed.
- Independent review found no blocking issues. Documentation notes that the target group's cross-zone setting must inherit the LB setting or explicitly enable it.
- Prepared `/tmp/sftpgo-prod-client-ip.patch`, parsed the resulting YAML and verified existing Service port, scheme, annotations and other fields are preserved. `git apply --check --unidiff-zero` passes against the supplied consumer repository. It is independent of the Issue 1 patch. No source credentials are included.
- Module default stays Cluster; consumer patch selects Local and the modern cross-zone attribute annotation. No code commit, registry release, prod YAML edit or live apply was performed. Real client-IP and NLB health verification remains a deployment acceptance requirement after publishing/selecting the new module version.

## 2026-09-30 pre-change plan: remaining operational gaps

Continue existing approved feature package and implementation request. Baseline: Helm 0.45.0 already supports envVars.secretKeyRef, podTerminationGracePeriodSeconds, pdb, podAnnotations and nodeSelector. Keep current provider/layout and wrapper scope; no new module sourcing or direct resource fallback. Governance: constitution terraform-module-developer references. Modern capabilities: supported, existing Helm/Kubernetes capabilities; no provider bump.

Narrow compatible additions: optional web_session.signing_passphrase_secret_ref with exactly-one validation and env injection; bootstrap_users defaults [] and suppresses bootstrap sidecar; nullable shutdown object defaults (when enabled) grace_time=300, termination_grace_period_seconds=330 with positive integer and ordering validation. No broad chart passthrough expansion, breaking change, required consumer migration or live mutation. The user explicitly requested implementing remaining module-owned issue fixes. Existing extra_values precedence remains unchanged and must be documented for envVars overrides.

Files: variables.tf, locals.tf, README.md, basic example/docs, tests (mocked Terraform and pinned Helm rendering), and this package contract/tasks. Test first with missing capability failures, then all existing tests, exact-chart render, validate module/example/fixture, Ruby regression checks, fmt/diff. Runtime upload completion is not proven by static rendering; document dev acceptance including NLB draining and Helm timeout.

### Remaining-gap verification evidence (2026-09-30)

- Tests first failed on empty bootstrap_users, then the missing signing Secret input, then undeclared/missing shutdown settings. Each capability was implemented after its failure.
- Full mocked Terraform suite: 30 passed, 0 failed. No cluster credentials/live resources used. Legacy proxy/session and Service behavior remain covered.
- Exact Helm chart 0.45.0 render passes both legacy and hardened scenarios: Secret reference without a ConfigMap signing literal, bootstrap omitted, custom 600/630 shutdown pair, existing S3 environment retained, policy/v1 PDB with matching selector, pod annotation and nodepool selector.
- terraform validate passed in module, examples/basic and tests/basic. Ruby bootstrap preservation/service stability checks passed. README generated tables refreshed and fmt/diff checks passed.
- Existing chart escape hatches cover PDB and placement without more public wrapper variables. Their use and single-replica consequences are documented, not enabled universally.
- No release, consumer hardening deployment, Secret provisioning/rotation, AWS lifecycle modification or runtime drain test performed. Existing Issue 3 consumer edits are preserved. Publish/select a real module release, synchronize the signing Secret, configure per-environment inputs, and validate on dev before production.
