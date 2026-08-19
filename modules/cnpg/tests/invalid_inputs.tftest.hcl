mock_provider "kubectl" {}

run "renders_cluster_without_credentials" {
  command = plan

  variables {
    name        = "test-postgres"
    namespace   = "test-platform"
    instances   = 2
    labels      = { "app.kubernetes.io/name" = "test-postgres" }
    annotations = { "example.com/owner" = "platform" }

    storage = {
      class = "hcloud-volumes"
      size  = "10Gi"
    }

    database = {
      name                  = "application"
      owner                 = "application_owner"
      bootstrap_secret_name = "application-postgres-owner"
    }

    postgresql_parameters = {
      password_encryption = "md5"
    }
  }

  assert {
    condition     = yamldecode(kubectl_manifest.cluster.yaml_body).spec.bootstrap.initdb.secret.name == "application-postgres-owner"
    error_message = "The Cluster must reference the existing bootstrap Secret."
  }

  assert {
    condition     = yamldecode(kubectl_manifest.cluster.yaml_body).spec.enableSuperuserAccess == false
    error_message = "The Cluster must disable superuser access by default."
  }

  assert {
    condition     = yamldecode(kubectl_manifest.cluster.yaml_body).spec.postgresql.parameters.password_encryption == "scram-sha-256" # pragma: allowlist secret
    error_message = "The module must enforce SCRAM password encryption."
  }

  assert {
    condition = (
      yamldecode(kubectl_manifest.cluster.yaml_body).spec.inheritedMetadata.labels["app.kubernetes.io/name"] == "test-postgres" &&
      yamldecode(kubectl_manifest.cluster.yaml_body).spec.inheritedMetadata.annotations["example.com/owner"] == "platform"
    )
    error_message = "Labels and annotations must be inherited by CNPG-managed resources."
  }

  assert {
    condition = (
      output.rw_service_hostname == "test-postgres-rw.test-platform.svc" &&
      output.ro_service_hostname == "test-postgres-ro.test-platform.svc" &&
      output.r_service_hostname == "test-postgres-r.test-platform.svc"
    )
    error_message = "All CNPG Service hostnames must be deterministic."
  }
}

run "accepts_decimal_storage_size" {
  command = plan

  variables {
    name      = "test-postgres"
    namespace = "test-platform"
    instances = 2

    storage = {
      class = "hcloud-volumes"
      size  = "1.5Gi"
    }

    database = {
      name                  = "application"
      owner                 = "application_owner"
      bootstrap_secret_name = "application-postgres-owner"
    }
  }
}

run "rejects_milli_byte_storage_size" {
  command = plan

  variables {
    name      = "test-postgres"
    namespace = "test-platform"
    instances = 2

    storage = {
      class = "hcloud-volumes"
      size  = "400m"
    }

    database = {
      name                  = "application"
      owner                 = "application_owner"
      bootstrap_secret_name = "application-postgres-owner"
    }
  }

  expect_failures = [var.storage]
}

run "rejects_long_database_owner" {
  command = plan

  variables {
    name      = "test-postgres"
    namespace = "test-platform"
    instances = 2

    storage = {
      class = "hcloud-volumes"
      size  = "10Gi"
    }

    database = {
      name                  = "application"
      owner                 = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
      bootstrap_secret_name = "application-postgres-owner"
    }
  }

  expect_failures = [var.database]
}
