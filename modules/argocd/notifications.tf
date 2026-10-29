locals {
  notifications_values = {
    for key, value in {
      enabled   = try(var.notifications.enabled, null)
      argocdUrl = try(var.notifications.argocd_url, null)
      context   = try(var.notifications.context, null)
      secret = try({
        for key, value in var.notifications.secret : key => value if value != null
      }, null)
      notifiers = try(var.notifications.notifiers, null)
      templates = try(var.notifications.templates, null)
      triggers  = try(var.notifications.triggers, null)
      subscriptions = try([
        for subscription in var.notifications.subscriptions : {
          for key, value in subscription : key => value if value != null
        }
      ], null)
    } : key => value if value != null
  }

  # Helm v2 redacts metadata only for paths registered with set_sensitive.
  # Use the final override value so these settings cannot undo extra_configs.
  notification_items_removed = (
    try(var.extra_configs.notifications == null, false) ||
    try(var.extra_configs.notifications.secret == null, false) ||
    try(var.extra_configs.notifications.secret.items == null, false)
  )
  notification_sensitive_items = {
    for key, value in coalesce(try(var.notifications.secret.items, null), {}) :
    key => try(var.extra_configs.notifications.secret.items[key], value)
    if !local.notification_items_removed && try(var.extra_configs.notifications.secret.items[key], value) != null
  }
}
