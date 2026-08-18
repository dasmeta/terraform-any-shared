locals {
  has_personal_access_token = nonsensitive(
    var.personal_access_token != null && try(trimspace(var.personal_access_token) != "", false)
  )
  has_existing_auth_secret = var.github_auth_secret_name != null && try(trimspace(var.github_auth_secret_name) != "", false)

  uses_legacy_deployment = var.deployment_mode == "legacy"
  uses_scale_set         = var.deployment_mode == "scale_set"

  scale_set_github_config_url = try(trimspace(var.scale_set.github_config_url), "")
  scale_set_controller_release_name = format(
    "arc-%s-%s",
    substr(var.scale_set.runner_scale_set_name, 0, min(length(var.scale_set.runner_scale_set_name), 44)),
    substr(sha1("${var.namespace}:${var.scale_set.runner_scale_set_name}:controller"), 0, 8),
  )
  scale_set_controller_service_account_name = "${local.scale_set_controller_release_name}-gha-rs-controller"

  repository_targets       = sort(tolist(var.runner_scope.repositories))
  organization_target      = try(trimspace(var.runner_scope.organization), "")
  legacy_repository_target = var.repo_name == null ? "" : trimspace(var.repo_name)
  uses_legacy_scope        = length(local.repository_targets) == 0 && local.organization_target == ""

  runner_scope_mode = local.uses_scale_set ? "scale_set" : (local.uses_legacy_scope ? "legacy_repository" : (
    local.organization_target != "" ? "organization" : "repositories"
  ))

  scoped_targets = local.uses_legacy_scope ? {} : (
    local.organization_target != "" ? { (local.organization_target) = "organization" } : {
      for repository in local.repository_targets : repository => "repository"
    }
  )

  normalized_runner_prefix = trim(replace(lower(var.runner_name), "/[^a-z0-9-]/", "-"), "-")
  runner_name_prefix       = local.normalized_runner_prefix == "" ? "runner" : local.normalized_runner_prefix

  scoped_runner_names = {
    for target, scope in local.scoped_targets : target => format(
      "%s-%s-%s",
      substr(local.runner_name_prefix, 0, min(length(local.runner_name_prefix), 20)),
      substr(trim(replace(lower(target), "/[^a-z0-9-]/", "-"), "-"), 0, min(length(trim(replace(lower(target), "/[^a-z0-9-]/", "-"), "-")), 25)),
      substr(sha1("${var.runner_name}:${scope}:${target}"), 0, 8),
    )
  }

  legacy_runner_document = templatefile("${path.module}/runner.yaml", {
    namespace   = var.namespace
    runner_name = var.runner_name
    scope       = "repository"
    target      = local.legacy_repository_target
  })

  scoped_runner_documents = {
    for target, scope in local.scoped_targets : target => templatefile("${path.module}/runner.yaml", {
      namespace   = var.namespace
      runner_name = local.scoped_runner_names[target]
      scope       = scope
      target      = target
    })
  }

  effective_runner_targets = local.uses_scale_set ? [local.scale_set_github_config_url] : (local.uses_legacy_scope ? [local.legacy_repository_target] : sort(keys(local.scoped_targets)))
  effective_runner_names   = local.uses_scale_set ? [] : (local.uses_legacy_scope ? [var.runner_name] : [for target in sort(keys(local.scoped_runner_names)) : local.scoped_runner_names[target]])
}
