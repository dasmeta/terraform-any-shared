mock_provider "helm" {}

run "rejects_fractional_database_port" {
  command = plan

  variables {
    namespace                 = "test-platform"
    configuration_secret_name = "authentik-configuration"

    database = {
      host = "postgresql.test.internal"
      name = "authentik"
      user = "authentik"
      port = 5432.5
    }
  }

  expect_failures = [
    var.database,
  ]
}

run "applies_extra_helm_config_before_enforced_values" {
  command = plan

  variables {
    namespace                 = "test-platform"
    configuration_secret_name = "authentik-configuration"

    database = {
      host = "postgresql.test.internal"
      name = "authentik"
      user = "authentik"
    }

    extra_helm_config = {
      postgresql = {
        enabled = true
      }
      server = {
        replicas = 2
      }
    }
  }

  assert {
    condition = (
      yamldecode(helm_release.this.values[0]).server.replicas == 2 &&
      yamldecode(helm_release.this.values[1]).postgresql.enabled == false
    )
    error_message = "extra_helm_config must be passed to Helm, while required module-owned values must retain precedence."
  }
}
