mock_provider "kubectl" {}

run "renders_typed_basic_auth_secret" {
  command = plan

  variables {
    name        = "test-database-bootstrap"
    namespace   = "test-platform"
    remote_key  = "test/database"
    labels      = { "app.kubernetes.io/name" = "test" }
    annotations = { "example.com/owner" = "platform" }

    secret_store = {
      name = "test-store"
      kind = "SecretStore"
    }

    target = {
      name            = "test-database-bootstrap"
      type            = "kubernetes.io/basic-auth"
      creation_policy = "Owner"
      deletion_policy = "Retain"
    }

    mappings = [
      {
        secret_key      = "username"
        remote_property = "database_username"
      },
      {
        secret_key      = "password"
        remote_property = "database_password"
      },
    ]
  }

  assert {
    condition = (
      yamldecode(kubectl_manifest.external_secret.yaml_body).apiVersion == "external-secrets.io/v1" &&
      yamldecode(kubectl_manifest.external_secret.yaml_body).spec.secretStoreRef.name == "test-store" &&
      yamldecode(kubectl_manifest.external_secret.yaml_body).spec.secretStoreRef.kind == "SecretStore"
    )
    error_message = "The ExternalSecret must use the configured v1 SecretStore reference."
  }

  assert {
    condition = (
      yamldecode(kubectl_manifest.external_secret.yaml_body).spec.target.name == "test-database-bootstrap" &&
      yamldecode(kubectl_manifest.external_secret.yaml_body).spec.target.template.type == "kubernetes.io/basic-auth" &&
      yamldecode(kubectl_manifest.external_secret.yaml_body).spec.target.creationPolicy == "Owner" &&
      yamldecode(kubectl_manifest.external_secret.yaml_body).spec.target.deletionPolicy == "Retain"
    )
    error_message = "The ExternalSecret must render the typed target and selected lifecycle policies."
  }

  assert {
    condition = (
      yamldecode(kubectl_manifest.external_secret.yaml_body).spec.data[0].remoteRef.key == "test/database" &&
      yamldecode(kubectl_manifest.external_secret.yaml_body).spec.data[0].secretKey == "username" &&
      yamldecode(kubectl_manifest.external_secret.yaml_body).spec.data[0].remoteRef.property == "database_username" &&
      yamldecode(kubectl_manifest.external_secret.yaml_body).spec.data[1].secretKey == "password" &&
      yamldecode(kubectl_manifest.external_secret.yaml_body).spec.data[1].remoteRef.property == "database_password"
    )
    error_message = "The ExternalSecret must map only configured provider properties to target keys."
  }

  assert {
    condition = (
      yamldecode(kubectl_manifest.external_secret.yaml_body).metadata.labels["app.kubernetes.io/name"] == "test" &&
      yamldecode(kubectl_manifest.external_secret.yaml_body).metadata.annotations["example.com/owner"] == "platform"
    )
    error_message = "The ExternalSecret must retain caller labels and annotations."
  }
}

run "rejects_duplicate_target_keys" {
  command = plan

  variables {
    name       = "test-configuration"
    namespace  = "test-platform"
    remote_key = "test/configuration"
    secret_store = {
      name = "test-store"
    }
    target = {
      name = "test-configuration"
    }
    mappings = [
      { secret_key = "password", remote_property = "first" },
      { secret_key = "password", remote_property = "second" },
    ]
  }

  expect_failures = [var.mappings]
}

run "rejects_invalid_target_policy" {
  command = plan

  variables {
    name       = "test-configuration"
    namespace  = "test-platform"
    remote_key = "test/configuration"
    secret_store = {
      name = "test-store"
    }
    target = {
      name            = "test-configuration"
      creation_policy = "Replace"
    }
    mappings = [
      { secret_key = "password", remote_property = "password" },
    ]
  }

  expect_failures = [var.target]
}
