# Ephemeral Namespace Deletion Design

## Purpose

Extend `modules/ephemeral-cleanup-cronjob` so each scheduled cleanup removes every namespace matching `namespace_name_pattern`. Namespace deletion removes direct resources, including SeaweedFS deployments, that Helm-only cleanup cannot discover.

## Behavior

`namespace_deletion.enabled` defaults to `true`. On every scheduled run, the job lists matching namespaces, uninstalls Helm releases, and then deletes each successfully cleaned namespace with `kubectl delete namespace --ignore-not-found=true --wait=false`.

The policy intentionally has no age, label, merge-request-state, or active-environment exemption. Consumers that need Helm-only cleanup must set `namespace_deletion.enabled = false`.

## Safety and Verification

- Dry-run logs Helm and namespace deletion commands without mutation.
- Helm discovery or uninstall failure prevents deletion of that namespace and makes the job fail.
- The test suite covers direct deletion of matching namespaces, dry-run behavior, and Helm-only mode.
