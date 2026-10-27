locals {
  events = {
    on-sync-running = {
      title    = "Sync started"
      when     = "app.status?.operationState?.phase == 'Running'"
      once_per = "app.status.operationState.startedAt"
    }
    on-deployed = {
      title    = "Deployment succeeded"
      when     = "app.status?.operationState?.phase == 'Succeeded' && app.status?.sync?.status == 'Synced' && app.status?.health?.status == 'Healthy'"
      once_per = "app.status.operationState.startedAt"
    }
    on-sync-failed = {
      title    = "Sync failed"
      when     = "app.status?.operationState?.phase in ['Failed', 'Error']"
      once_per = "app.status.operationState.startedAt"
    }
    on-health-degraded = {
      title    = "Application degraded"
      when     = "app.status?.health?.status == 'Degraded'"
      once_per = null
    }
  }

  messages = {
    for name, event in local.events : name => templatefile("${path.module}/message.tftpl", {
      title                = event.title
      use_operation_result = name != "on-health-degraded"
    })
  }
}

module "argocd" {
  source = "../.."

  hostname                  = "argocd.example.com"
  use_existing_admin_secret = true

  notifications = {
    enabled    = true
    argocd_url = "https://argocd.example.com"
    context    = { environment = "dev" }
    secret = {
      create = false
      name   = "argocd-notifications-external"
    }
    notifiers = {
      "service.slack" = yamlencode({ token = "$slack-token" })
      "service.teams-workflows" = yamlencode({
        recipientUrls = { example-deployments = "$teams-workflow-url" }
      })
    }
    templates = {
      for name, event in local.events : "template.${name}" => yamlencode({
        message = local.messages[name]
        teams-workflows = {
          title = event.title
          text  = local.messages[name]
        }
      })
    }
    triggers = {
      for name, event in local.events : "trigger.${name}" => yamlencode([
        merge(
          { when = event.when, send = [name] },
          event.once_per == null ? {} : { oncePer = event.once_per },
        )
      ])
    }
    subscriptions = [{
      recipients = ["slack:example-deployments", "teams-workflows:example-deployments"]
      triggers   = sort(keys(local.events))
      selector   = "environment=dev"
    }]
  }
}
