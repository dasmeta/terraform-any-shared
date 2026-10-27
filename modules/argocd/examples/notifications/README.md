# Argo CD with Slack and Teams notifications

This Terraform example configures the module's native `notifications` input for
Slack and Teams Workflows. It uses generic settings and existing Secrets.

Configure the Helm provider in `0-setup.tf` for your cluster and replace the
example hostname and recipients in `1-example.tf`. For ingress/ALB configuration,
see the [basic example](../basic).

Prerequisites in the `argocd` namespace:

- An existing `argocd-secret` for admin credentials.
- An externally managed `argocd-notifications-external` Secret containing
  `slack-token` and `teams-workflow-url`.
- The Slack bot invited to the destination channel and a Teams Workflow
  configured for the destination Teams channel.

The Teams recipient `teams-workflows:example-deployments` matches the
`example-deployments` notifier entry; the Workflow URL determines its channel.
No credentials are included in this example.

Subscriptions select **Application** objects labeled `environment=dev`. Set that
label in the Application manifest or adjust the selector to your own labels.

| Event | Condition |
|-------|-----------|
| Sync started | Operation phase `Running` |
| Deployment succeeded | Operation `Succeeded`, application `Synced` and `Healthy` |
| Sync failed | Operation phase `Failed` or `Error` |
| Application degraded | Application health `Degraded` |

Messages include application name, environment, destination namespace, status,
and the Argo CD link. Single- and multi-source revisions use matching status
source metadata; Git commits and Helm chart versions are labeled separately.
Unavailable revisions and last-compared state are identified explicitly.

Start/success/failure use `operationState.startedAt` for suppression, so another
sync of the same revision can notify again. Degradation can notify again after
an observed recovery. Initial subscriptions may notify about an already matching
state; fast transitions can be missed. This is status observation rather than
exactly-once event delivery.

Use `secret.create = true` with sensitive `secret.items` inputs if you prefer
Helm-managed credentials; those values remain in Terraform and Helm state.
Keep credential values out of notifier/template definitions and committed files.

`extra_configs` remains the final override for advanced Helm settings. Omission
of the whole `notifications` input preserves the module's existing behavior.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_argocd"></a> [argocd](#module\_argocd) | ../.. | n/a |

## Resources

No resources.

## Inputs

No inputs.

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
