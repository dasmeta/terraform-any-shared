mock_provider "kubernetes" {}

run "rejects_non_dns1123_namespace_name" {
  command = plan

  variables {
    name = "Team A"
  }

  expect_failures = [
    var.name,
  ]
}
