mock_provider "helm" {}
mock_provider "kubernetes" {}

variables {
  admin = { password = "test-admin-password" }
  s3_storage = {
    bucket        = "test-sftpgo"
    region        = "eu-central-1"
    access_key    = "test-key"
    access_secret = "test-secret"
  }
  bootstrap_users = []
}

run "no_bootstrap_accounts" {
  command = plan
  assert {
    condition     = length(yamldecode(helm_release.this.values[0]).extraContainers) == 0
    error_message = "Empty bootstrap_users must omit the credential-bearing bootstrap sidecar."
  }
}

run "secret_reference_with_proxy" {
  command = plan
  variables {
    web_session = { signing_passphrase_secret_ref = { name = "test-session", key = "signing" } }
    web_proxy   = { proxy_allowed = ["10.0.1.0/24"] }
  }
  assert {
    condition = (
      !can(yamldecode(helm_release.this.values[0]).config.httpd.signing_passphrase) &&
      yamldecode(helm_release.this.values[0]).envVars[0].valueFrom.secretKeyRef.name == "test-session" &&
      yamldecode(helm_release.this.values[0]).envVars[0].valueFrom.secretKeyRef.key == "signing" &&
      yamldecode(helm_release.this.values[0]).envVars[0].name == "SFTPGO_HTTPD__SIGNING_PASSPHRASE" &&
      yamldecode(helm_release.this.values[0]).config.httpd.token_validation == 0 &&
      yamldecode(helm_release.this.values[0]).config.httpd.bindings[0].port == 8080
    )
    error_message = "Signing must use a Secret reference, preserve proxy settings and omit a literal from the ConfigMap."
  }
}

run "paired_shutdown" {
  command = plan
  variables { shutdown = {} }
  assert {
    condition = (
      yamldecode(helm_release.this.values[0]).env.SFTPGO_GRACE_TIME == "300" &&
      yamldecode(helm_release.this.values[0]).podTerminationGracePeriodSeconds == 330 &&
      yamldecode(helm_release.this.values[0]).env.SFTPGO_DEFAULT_ADMIN_PASSWORD == "test-admin-password"
    )
    error_message = "Shutdown must set both timeouts while preserving existing environment variables."
  }
}

run "defaults_preserve_shutdown" {
  command = plan
  assert {
    condition = (
      !can(yamldecode(helm_release.this.values[0]).podTerminationGracePeriodSeconds) &&
      !can(yamldecode(helm_release.this.values[0]).env.SFTPGO_GRACE_TIME)
    )
    error_message = "Shutdown must remain opt-in."
  }
}

run "reject_both_signing_sources" {
  command = plan
  variables {
    web_session = {
      signing_passphrase            = "test-literal"
      signing_passphrase_secret_ref = { name = "test-session", key = "signing" }
    }
  }
  expect_failures = [var.web_session]
}

run "reject_missing_signing_source" {
  command = plan
  variables { web_session = {} }
  expect_failures = [var.web_session]
}

run "reject_blank_secret_key" {
  command = plan
  variables { web_session = { signing_passphrase_secret_ref = { name = "test-session", key = " " } } }
  expect_failures = [var.web_session]
}

run "reject_short_pod_shutdown" {
  command = plan
  variables { shutdown = { grace_time = 300, termination_grace_period_seconds = 300 } }
  expect_failures = [var.shutdown]
}

run "reject_fractional_shutdown" {
  command = plan
  variables { shutdown = { grace_time = 1.5 } }
  expect_failures = [var.shutdown]
}

run "reject_disabled_grace" {
  command = plan
  variables { shutdown = { grace_time = 0 } }
  expect_failures = [var.shutdown]
}
