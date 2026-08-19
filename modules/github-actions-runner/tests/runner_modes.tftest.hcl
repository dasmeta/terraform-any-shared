mock_provider "helm" {}
mock_provider "kubectl" {}

run "uses_existing_auth_secret_with_environment_credentials" {
  command = plan

  variables {
    personal_access_token   = null
    github_auth_secret_name = "controller-manager"
    kubectl_config_path     = null
    repo_name               = "example/application"
    namespace               = "github-actions-runner"
    chart_version           = "0.23.7"
  }

  assert {
    condition = (
      one([for setting in helm_release.test.set : setting.value if setting.name == "authSecret.create"]) == "false" &&
      one([for setting in helm_release.test.set : setting.value if setting.name == "authSecret.name"]) == "controller-manager" &&
      helm_release.test.namespace == "github-actions-runner" &&
      helm_release.test.version == "0.23.7" &&
      yamldecode(kubectl_manifest.pv_mongo_main[0].yaml_body).metadata.namespace == "github-actions-runner"
    )
    error_message = "Existing-Secret mode must use the configured Secret, namespace, and chart version."
  }

  assert {
    condition     = output.runner_scope_mode == "legacy_repository"
    error_message = "Omitting runner_scope must preserve the legacy repository mode."
  }
}

run "rejects_missing_authentication" {
  command = plan

  variables {
    personal_access_token = null
    repo_name             = "example/application"
  }

  expect_failures = [helm_release.test]
}

run "rejects_mixed_authentication" {
  command = plan

  variables {
    personal_access_token   = "example-token-value"
    github_auth_secret_name = "controller-manager"
    repo_name               = "example/application"
  }

  expect_failures = [helm_release.test]
}

run "includes_full_runner_name_in_scoped_name_hash" {
  command = plan

  variables {
    runner_name             = "very-long-runner-name-alpha"
    personal_access_token   = null
    github_auth_secret_name = "controller-manager"

    runner_scope = {
      organization = "example"
    }
  }

  assert {
    condition = endswith(
      output.runner_resource_names[0],
      substr(sha1("very-long-runner-name-alpha:organization:example"), 0, 8),
    )
    error_message = "Scoped runner hashes must include the full runner name to prevent truncated-prefix collisions."
  }
}

run "rejects_missing_runner_target" {
  command = plan

  variables {
    personal_access_token   = null
    github_auth_secret_name = "controller-manager"
    repo_name               = null
  }

  expect_failures = [helm_release.test]
}

run "renders_multiple_repository_runners" {
  command = plan

  variables {
    personal_access_token   = null
    github_auth_secret_name = "controller-manager"
    kubectl_config_path     = null

    runner_scope = {
      repositories = [
        "example/api.service",
        "example/web_service",
        "example/api.service",
      ]
    }
  }

  assert {
    condition = (
      length(kubectl_manifest.pv_mongo_main) == 0 &&
      length(kubectl_manifest.scoped_runner) == 2 &&
      length(output.runner_resource_names) == 2 &&
      length(toset(output.runner_resource_names)) == 2
    )
    error_message = "Repository collection mode must create one uniquely named runner per unique repository."
  }

  assert {
    condition = alltrue([
      for target, manifest in kubectl_manifest.scoped_runner :
      yamldecode(manifest.yaml_body).spec.repository == target
    ])
    error_message = "Every repository runner manifest must target its map key."
  }

  assert {
    condition = alltrue([
      for name in output.runner_resource_names :
      can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", name)) && length(name) <= 63
    ])
    error_message = "Generated runner names must be unique Kubernetes DNS labels."
  }
}

run "renders_organization_runner" {
  command = plan

  variables {
    personal_access_token   = null
    github_auth_secret_name = "controller-manager"

    runner_scope = {
      organization = "example"
    }
  }

  assert {
    condition = (
      output.runner_scope_mode == "organization" &&
      length(output.runner_targets) == 1 &&
      output.runner_targets[0] == "example" &&
      yamldecode(kubectl_manifest.scoped_runner["example"].yaml_body).spec.organization == "example"
    )
    error_message = "Organization mode must create one organization-scoped Runner manifest."
  }
}

run "rejects_mixed_runner_scope" {
  command = plan

  variables {
    personal_access_token   = null
    github_auth_secret_name = "controller-manager"

    runner_scope = {
      repositories = ["example/application"]
      organization = "example"
    }
  }

  expect_failures = [var.runner_scope]
}

run "preserves_legacy_repository_contract" {
  command = plan

  variables {
    runner_name           = "runner"
    repo_name             = "example/application"
    personal_access_token = "example-token-value"
    kubectl_config_path   = "~/.kube/config"
  }

  assert {
    condition = (
      length(kubectl_manifest.pv_mongo_main) == 1 &&
      yamldecode(kubectl_manifest.pv_mongo_main[0].yaml_body).metadata.name == "runner" &&
      yamldecode(kubectl_manifest.pv_mongo_main[0].yaml_body).metadata.namespace == "actions-runner-system" &&
      yamldecode(kubectl_manifest.pv_mongo_main[0].yaml_body).spec.repository == "example/application"
    )
    error_message = "Legacy mode must retain the historical runner name, namespace, target, and resource address."
  }

  assert {
    condition = (
      one([for setting in helm_release.test.set : setting.value if setting.name == "authSecret.create"]) == "true" &&
      one([for setting in helm_release.test.set_sensitive : nonsensitive(setting.value) if setting.name == "authSecret.github_token"]) == "example-token-value"
    )
    error_message = "Legacy token mode must create the chart Secret with the supplied sensitive token."
  }
}
