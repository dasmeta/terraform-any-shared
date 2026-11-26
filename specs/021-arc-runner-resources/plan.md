# Implementation Plan: ARC runner resource budgets

## Current state and design

`modules/github-actions-runner` wraps the official ARC Helm charts. It exposes runner count and uses the chart's built-in DinD template, which hardcodes the Docker daemon and does not pass through resource requirements. The module currently has no resource input.

Add optional `scale_set.container_resources` accepting exactly `runner` and `dind` with CPU and memory requests and limits. When supplied, use the documented custom pod template with the standard ordinary DinD sidecar. Preserve the existing chart mode when omitted. The opt-in layout targets the supported ordinary-sidecar behavior used by the affected Kubernetes 1.27 cluster. Keep the controller, authentication and Terraform/Helm provider constraints stable.

## Standards and compatibility

This is an extension of an existing official Helm wrapper. No new module, provider or automation is needed. The Helm provider's existing values argument and the ARC chart's custom pod template are supported capabilities. Keep the interface narrow and preserve the legacy path. Follow the Infra Governance [Speckit gate](https://github.com/dasmeta/infra-governance/blob/main/workflows/speckit-module-change-gate.md) with the spec, plan and tasks in this directory.

## Files and validation

Update the scale-set inputs and Helm values wiring, add a compact DinD values template, and update the official scale-set example, documentation and mocked Terraform tests. Render the same chart and Kubernetes version with and without the opt-in, comparing the runner pod specs after removing only the new resource blocks. Run module formatting, validation and all native Terraform tests.

## Delivery

Release the shared module before pinning it in the product infrastructure repository. Verify scope on the Terraform Cloud plan, then verify live requests, limits, ready runner pods and a heavy build after approved deployment. The consuming workspace's memory decisions are 3 GiB for the runner and 1536 MiB for the Docker daemon, with the same requests. Node-pool configuration is outside this change.
