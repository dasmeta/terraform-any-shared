mock_provider "helm" {}

run "disabled_by_default" {
  command = plan

  assert {
    condition     = length(helm_release.retention) == 0
    error_message = "Existing consumers must not create retention resources."
  }

  assert {
    condition     = length(helm_release.this.values) == 2 && helm_release.this.version == var.chart_version
    error_message = "Retention must preserve the original application values and version contract."
  }
}

run "enabled_with_existing_secret" {
  command = plan

  variables {
    retention = {
      enabled          = true
      api_url          = "https://defectdojo.example.com"
      engagement_ids   = [7, 9]
      api_token_secret = { name = "example-retention-token" }
    }
  }

  assert {
    condition     = length(helm_release.retention) == 1 && endswith(helm_release.retention[0].chart, "/charts/retention")
    error_message = "Enabled retention must use the packaged companion Helm chart."
  }

  assert {
    condition     = jsondecode(helm_release.retention[0].values[0]).apiTokenSecret.name == "example-retention-token" && jsondecode(helm_release.retention[0].values[0]).apiTokenSecret.key == "api-key"
    error_message = "Pass only existing Secret references, never token values."
  }

  assert {
    condition     = jsondecode(helm_release.retention[0].values[0]).policy.days == 30 && toset(jsondecode(helm_release.retention[0].values[0]).policy.engagement_ids) == toset([7, 9])
    error_message = "The policy must preserve explicit scope and conservative expiry."
  }

  assert {
    condition     = jsondecode(helm_release.retention[0].values[0]).timeZone == "Etc/UTC" && length(jsondecode(helm_release.retention[0].values[0]).contentChecksum) == 64
    error_message = "Use explicit time zone and track bundled chart/worker updates."
  }
}

run "missing_scope_is_invalid" {
  command = plan
  variables {
    retention = {
      enabled          = true
      api_url          = "https://defectdojo.example.com"
      api_token_secret = { name = "example-token" }
    }
  }
  expect_failures = [var.retention]
}

run "missing_secret_is_invalid" {
  command = plan
  variables {
    retention = {
      enabled        = true
      api_url        = "https://defectdojo.example.com"
      engagement_ids = [7]
    }
  }
  expect_failures = [var.retention]
}

run "invalid_retention_days" {
  command = plan
  variables {
    retention = { days = 0 }
  }
  expect_failures = [var.retention]
}

run "invalid_scope_id" {
  command = plan
  variables {
    retention = { engagement_ids = [-1] }
  }
  expect_failures = [var.retention]
}

run "invalid_schedule" {
  command = plan
  variables {
    retention = { schedule = "@daily" }
  }
  expect_failures = [var.retention]
}

run "invalid_request_limit" {
  command = plan
  variables {
    retention = { max_tests_per_run = 101 }
  }
  expect_failures = [var.retention]
}

run "enabled_with_named_scope" {
  command = plan
  variables {
    retention = {
      enabled          = true
      api_url          = "https://defectdojo.example.com"
      api_token_secret = { name = "example-token" }
      engagement_names = ["frontend", "backend"]
    }
  }
  assert {
    condition     = toset(jsondecode(helm_release.retention[0].values[0]).policy.engagement_names) == toset(["frontend", "backend"]) && length(jsondecode(helm_release.retention[0].values[0]).policy.engagement_ids) == 0 && !jsondecode(helm_release.retention[0].values[0]).policy.all_engagements
    error_message = "Named scope must be passed without silently enabling global scope."
  }
}

run "explicit_all_scope" {
  command = plan
  variables {
    retention = {
      enabled          = true
      api_url          = "https://defectdojo.example.com"
      api_token_secret = { name = "example-token" }
      all_engagements  = true
    }
  }
  assert {
    condition     = jsondecode(helm_release.retention[0].values[0]).policy.all_engagements && length(jsondecode(helm_release.retention[0].values[0]).policy.engagement_names) == 0 && length(jsondecode(helm_release.retention[0].values[0]).policy.engagement_ids) == 0
    error_message = "All-scope must require the explicit flag."
  }
}

run "combined_names_and_ids_are_invalid" {
  command = plan
  variables {
    retention = { engagement_ids = [7], engagement_names = ["backend"] }
  }
  expect_failures = [var.retention]
}

run "combined_all_and_names_are_invalid" {
  command = plan
  variables {
    retention = { all_engagements = true, engagement_names = ["backend"] }
  }
  expect_failures = [var.retention]
}

run "empty_name_is_invalid" {
  command = plan
  variables {
    retention = { engagement_names = [" "] }
  }
  expect_failures = [var.retention]
}

run "bootstrap_is_disabled_by_default" {
  command = plan
  assert {
    condition     = length(helm_release.retention_bootstrap) == 0
    error_message = "Existing consumers must not create bootstrap credentials or RBAC."
  }
}

run "managed_token_default_name" {
  command = plan
  variables {
    retention = {
      enabled          = true
      api_url          = "https://defectdojo.example.com"
      all_engagements  = true
      api_token_secret = { create = true }
    }
  }
  assert {
    condition     = length(helm_release.retention_bootstrap) == 1 && helm_release.retention_bootstrap[0].wait && helm_release.retention_bootstrap[0].timeout == 900
    error_message = "Managed token mode must wait for a bounded bootstrap release."
  }
  assert {
    condition     = jsondecode(helm_release.retention_bootstrap[0].values[0]).targetSecret.name == "defectdojo-retention" && jsondecode(helm_release.retention[0].values[0]).apiTokenSecret.name == "defectdojo-retention"
    error_message = "Bootstrap and cleanup must refer to the same generated Secret."
  }
  assert {
    condition     = jsondecode(helm_release.retention_bootstrap[0].values[0]).sourceFullname == "defectdojo" && jsondecode(helm_release.retention_bootstrap[0].values[0]).applicationRelease == "defectdojo"
    error_message = "Default credential source must match the upstream chart fullname."
  }
}

run "managed_token_source_fullname_override" {
  command = plan
  variables {
    name           = "example"
    custom_configs = { fullnameOverride = "example-security" }
    retention = {
      enabled          = true
      api_url          = "https://defectdojo.example.com"
      all_engagements  = true
      api_token_secret = { create = true, name = "example-api-token", key = "token" }
    }
  }
  assert {
    condition     = jsondecode(helm_release.retention_bootstrap[0].values[0]).sourceFullname == "example-security" && jsondecode(helm_release.retention[0].values[0]).apiTokenSecret.key == "token"
    error_message = "Honor application fullname and custom token Secret/key."
  }
}

run "managed_source_name_override_contained_in_release" {
  command = plan
  variables {
    name           = "example-security"
    custom_configs = { nameOverride = "security" }
    retention = {
      enabled          = true
      api_url          = "https://defectdojo.example.com"
      all_engagements  = true
      api_token_secret = { create = true }
    }
  }
  assert {
    condition     = jsondecode(helm_release.retention_bootstrap[0].values[0]).sourceFullname == "example-security"
    error_message = "Upstream does not append a chart name already contained in the release name."
  }
}

run "managed_source_explicit_empty_override_matches_upstream" {
  command = plan
  variables {
    name            = "example"
    default_configs = { nameOverride = "security" }
    custom_configs  = { nameOverride = "" }
    retention = {
      enabled          = true
      api_url          = "https://defectdojo.example.com"
      all_engagements  = true
      api_token_secret = { create = true }
    }
  }
  assert {
    condition     = jsondecode(helm_release.retention_bootstrap[0].values[0]).sourceFullname == "example-defectdojo"
    error_message = "Explicit empty custom nameOverride must override the default map before chart fallback."
  }
}

run "disabled_retention_does_not_bootstrap" {
  command = plan
  variables {
    retention = { enabled = false, api_token_secret = { create = true } }
  }
  assert {
    condition     = length(helm_release.retention_bootstrap) == 0 && length(helm_release.retention) == 0
    error_message = "No bootstrap or cleanup when retention itself is disabled."
  }
}

run "invalid_managed_name_is_rejected" {
  command = plan
  variables {
    retention = {
      enabled          = true
      api_url          = "https://defectdojo.example.com"
      all_engagements  = true
      api_token_secret = { create = true, name = "BAD/name" }
    }
  }
  expect_failures = [var.retention]
}
