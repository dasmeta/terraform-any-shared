# Feature Specification: ARC runner resource budgets

**Feature Branch**: `codex/arc-runner-resource-budgets`
**Created**: 2026-11-26
**Status**: Ready for implementation
**Input**: Allow scale sets to configure per-container requests and limits.

## Module Context

- **Target Module Path**: `modules/github-actions-runner`
- **Related Files In Scope**: Terraform configuration, chart values, module documentation, example and tests.
- **Upstream Baseline**: Official ARC 0.14.2 Helm chart with Docker-in-Docker.
- **Requested Interface Change**: An optional resource budget for each of the runner and Docker daemon.
- **Breaking Change / Interface Widening**: Additive and opt-in. Existing callers retain their current resources and chart defaults.

## User Scenarios & Testing

### Platform operator protects shared runners (P1)

An operator sets independent CPU and memory requests and limits to make scheduling account for job resource consumption and bound memory use during bursts.

1. Given a scale set with explicit budgets, when the chart renders, then the runner and Docker daemon each receive their own CPU and memory requests and limits.
2. Given a scale set with explicit budgets, when it starts on Kubernetes 1.27, then Docker builds and container jobs retain the existing socket, mounts and startup behavior.
3. Given a caller without configured budgets, when it plans, then the release continues using the built-in Docker-in-Docker mode.
4. Given a partial resource configuration, when Terraform validates it, then it rejects the input before applying a release.

## Requirements

- **FR-001**: Supply both CPU and memory requests and limits for each of the two containers when opting in.
- **FR-002**: Keep the release names, chart pins, controller, authentication and default behavior stable.
- **FR-003**: Render one runner and one Docker daemon with the supported ordinary-sidecar pod layout.

## Success Criteria

- **SC-001**: Removing only the two resource blocks from the customized rendered ARS pod spec yields the built-in DinD pod spec on Kubernetes 1.27.
- **SC-002**: Existing module tests pass and the opt-in plan renders separate budgets.
- **SC-003**: The downstream deployment verifies scoped chart changes, live resources, scheduling and a representative heavy Docker build.
