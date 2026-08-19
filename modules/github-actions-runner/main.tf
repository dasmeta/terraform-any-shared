resource "kubectl_manifest" "pv_mongo_main" {
  count     = local.uses_legacy_deployment && local.uses_legacy_scope ? 1 : 0
  yaml_body = local.legacy_runner_document

  depends_on = [helm_release.legacy]
}

resource "kubectl_manifest" "scoped_runner" {
  for_each  = local.uses_legacy_deployment ? local.scoped_runner_documents : {}
  yaml_body = each.value

  depends_on = [helm_release.legacy]
}

resource "helm_release" "legacy" {
  count            = local.uses_legacy_deployment ? 1 : 0
  namespace        = var.namespace
  repository       = "https://actions-runner-controller.github.io/actions-runner-controller"
  chart            = "actions-runner-controller"
  name             = "actions-runner-controller"
  version          = var.chart_version
  create_namespace = true

  set {
    name  = "authSecret.create"
    value = tostring(local.has_personal_access_token)
  }

  dynamic "set" {
    for_each = local.has_existing_auth_secret ? [var.github_auth_secret_name] : []

    content {
      name  = "authSecret.name"
      value = set.value
    }
  }

  dynamic "set_sensitive" {
    for_each = local.has_personal_access_token ? [var.personal_access_token] : []

    content {
      name  = "authSecret.github_token"
      value = set_sensitive.value
    }
  }

  lifecycle {
    precondition {
      condition     = !local.uses_legacy_scope || local.legacy_repository_target != ""
      error_message = "repo_name must be provided when runner_scope is empty."
    }

    precondition {
      condition     = local.has_personal_access_token != local.has_existing_auth_secret
      error_message = "Exactly one of personal_access_token or github_auth_secret_name must be provided."
    }
  }
}

resource "helm_release" "arc_scale_set_controller" {
  count            = local.uses_scale_set ? 1 : 0
  name             = local.scale_set_controller_release_name
  namespace        = var.namespace
  repository       = "oci://ghcr.io/actions/actions-runner-controller-charts"
  chart            = "gha-runner-scale-set-controller"
  version          = var.scale_set.controller_chart_version
  create_namespace = true

  set {
    name  = "flags.watchSingleNamespace"
    value = var.namespace
  }
}

resource "helm_release" "arc_scale_set" {
  count            = local.uses_scale_set ? 1 : 0
  name             = var.scale_set.runner_scale_set_name
  namespace        = var.namespace
  repository       = "oci://ghcr.io/actions/actions-runner-controller-charts"
  chart            = "gha-runner-scale-set"
  version          = var.scale_set.chart_version
  create_namespace = true

  set {
    name  = "githubConfigUrl"
    value = local.scale_set_github_config_url
  }

  set {
    name  = "runnerScaleSetName"
    value = var.scale_set.runner_scale_set_name
  }

  set {
    name  = "minRunners"
    value = tostring(var.scale_set.min_runners)
  }

  set {
    name  = "maxRunners"
    value = tostring(var.scale_set.max_runners)
  }

  set {
    name  = "containerMode.type"
    value = "dind"
  }

  set {
    name  = "controllerServiceAccount.namespace"
    value = var.namespace
  }

  set {
    name  = "controllerServiceAccount.name"
    value = local.scale_set_controller_service_account_name
  }

  dynamic "set" {
    for_each = local.has_existing_auth_secret ? [var.github_auth_secret_name] : []

    content {
      name  = "githubConfigSecret"
      value = set.value
    }
  }

  dynamic "set_sensitive" {
    for_each = local.has_personal_access_token ? [var.personal_access_token] : []

    content {
      name  = "githubConfigSecret.github_token"
      value = set_sensitive.value
    }
  }

  depends_on = [helm_release.arc_scale_set_controller]

  lifecycle {
    precondition {
      condition     = local.has_personal_access_token != local.has_existing_auth_secret
      error_message = "Exactly one of personal_access_token or github_auth_secret_name must be provided."
    }
  }
}
