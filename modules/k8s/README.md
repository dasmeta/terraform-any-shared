# Generic Kubernetes Modules

This directory groups reusable, cluster-agnostic Kubernetes capabilities.
Consumers configure Kubernetes provider connectivity in their Terraform root;
the modules here do not assume a particular cloud or Kubernetes distribution.

## Contents

- [`namespace`](namespace/README.md) creates one Kubernetes namespace with
  caller-managed labels and annotations.
- `grafana-dashboard.json` is an existing Grafana dashboard asset retained at
  its established path for compatibility. It is not a Terraform module.
