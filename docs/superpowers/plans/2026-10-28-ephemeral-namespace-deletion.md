# Ephemeral Namespace Deletion Implementation Plan

**Goal:** Delete all matching ephemeral namespaces on each scheduled cleanup run.

1. Set the grouped `namespace_deletion.enabled` default to `true` and render it as `DELETE_NAMESPACES`.
2. Grant namespace delete permission only when the consumer explicitly disables neither the default nor the setting.
3. Remove creation-time parsing and delete every successfully Helm-cleaned matching namespace.
4. Update shell tests, README, example, and Speckit evidence to document immediate scheduled deletion.
5. Verify Terraform formatting, module and example validation, shell behavior tests, and diff integrity.
