mock_provider "kubectl" {}

run "renders_cluster_without_credentials" {
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
      owner                 = "application_owner"
      bootstrap_secret_name = "application-postgres-owner"
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
    condition     = output.rw_service_hostname == "test-postgres-rw.test-platform.svc"
    error_message = "The read/write Service hostname must be deterministic."
  }
}

run "renders_backup_without_credential_values" {
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
      owner                 = "application_owner"
      bootstrap_secret_name = "application-postgres-owner"
    }

    backup = {
      destination_path        = "s3://database-backups/test-postgres"
      credentials_secret_name = "database-backup-credentials"
      endpoint_url            = "https://object.example.internal"
    }
  }

  assert {
    condition     = yamldecode(kubectl_manifest.cluster.yaml_body).spec.backup.barmanObjectStore.s3Credentials.secretAccessKey.name == "database-backup-credentials"
    error_message = "Backup configuration must render only the credential Secret reference."
  }

  assert {
    condition     = yamldecode(kubectl_manifest.scheduled_backup[0].yaml_body).metadata.name == "test-postgres-daily"
    error_message = "Backup configuration must create the daily ScheduledBackup."
  }
}

run "rejects_invalid_storage_size" {
  command = plan

  variables {
    name      = "test-postgres"
    namespace = "test-platform"
    instances = 2

    storage = {
      class = "hcloud-volumes"
      size  = "0Gi"
    }

    database = {
      name                  = "application"
      owner                 = "application_owner"
      bootstrap_secret_name = "application-postgres-owner"
    }
  }

  expect_failures = [var.storage]
}

run "rejects_invalid_backup_schedule" {
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
      owner                 = "application_owner"
      bootstrap_secret_name = "application-postgres-owner"
    }

    backup = {
      destination_path        = "s3://database-backups/test-postgres"
      credentials_secret_name = "database-backup-credentials"
      schedule                = "0 0 * * *"
    }
  }

  expect_failures = [var.backup]
}
