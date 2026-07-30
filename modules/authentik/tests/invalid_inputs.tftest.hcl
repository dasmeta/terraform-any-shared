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
