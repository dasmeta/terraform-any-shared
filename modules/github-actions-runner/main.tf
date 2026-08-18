resource "kubectl_manifest" "pv_mongo_main" {
  count     = local.uses_legacy_scope ? 1 : 0
  yaml_body = local.legacy_runner_document

  depends_on = [helm_release.test]
}

resource "kubectl_manifest" "scoped_runner" {
  for_each  = local.scoped_runner_documents
  yaml_body = each.value

  depends_on = [helm_release.test]
}

resource "helm_release" "test" {
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
