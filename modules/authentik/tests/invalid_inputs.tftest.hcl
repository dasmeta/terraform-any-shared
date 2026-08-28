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

run "requires_ingress_details_when_enabled" {
  command = plan

  variables {
    namespace                 = "test-platform"
    configuration_secret_name = "authentik-configuration"

    database = {
      host = "postgresql.test.internal"
      name = "authentik"
      user = "authentik"
    }

    ingress = {
      enabled = true
    }
  }

  expect_failures = [
    var.ingress,
  ]
}

run "rejects_invalid_ingress_resource_names" {
  command = plan

  variables {
    namespace                 = "test-platform"
    configuration_secret_name = "authentik-configuration"

    database = {
      host = "postgresql.test.internal"
      name = "authentik"
      user = "authentik"
    }

    ingress = {
      enabled         = true
      hostname        = "auth.example.com"
      tls_secret_name = "auth..tls"
      cluster_issuer  = "letsencrypt-.prod"
    }
  }

  expect_failures = [
    var.ingress,
  ]
}

run "preserves_extra_helm_ingress_when_typed_input_is_omitted" {
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
      server = {
        ingress = {
          enabled = true
        }
      }
    }
  }

  assert {
    condition = (
      yamldecode(helm_release.this.values[0]).server.ingress.enabled &&
      !can(yamldecode(helm_release.this.values[1]).server.ingress)
    )
    error_message = "Omitting typed ingress must preserve existing extra_helm_config ingress values."
  }
}

run "accepts_null_ingress" {
  command = plan

  variables {
    namespace                 = "test-platform"
    configuration_secret_name = "authentik-configuration"

    database = {
      host = "postgresql.test.internal"
      name = "authentik"
      user = "authentik"
    }

    ingress = null
  }

  assert {
    condition     = !can(yamldecode(helm_release.this.values[1]).server.ingress)
    error_message = "Null ingress must be treated as an omitted ingress configuration."
  }
}

run "renders_enabled_ingress_with_tls" {
  command = plan

  variables {
    namespace                 = "test-platform"
    configuration_secret_name = "authentik-configuration"

    database = {
      host = "postgresql.test.internal"
      name = "authentik"
      user = "authentik"
    }

    ingress = {
      enabled         = true
      hostname        = "auth.example.com"
      tls_secret_name = "auth-example-com-tls"
      cluster_issuer  = "letsencrypt-prod"
      annotations = {
        "example.com/annotation" = "example"
      }
    }
  }

  assert {
    condition = (
      yamldecode(helm_release.this.values[1]).server.ingress.enabled &&
      yamldecode(helm_release.this.values[1]).server.ingress.ingressClassName == "nginx" &&
      yamldecode(helm_release.this.values[1]).server.ingress.hosts == ["auth.example.com"] &&
      yamldecode(helm_release.this.values[1]).server.ingress.tls[0].secretName == "auth-example-com-tls" &&
      yamldecode(helm_release.this.values[1]).server.ingress.annotations["cert-manager.io/cluster-issuer"] == "letsencrypt-prod" &&
      yamldecode(helm_release.this.values[1]).server.ingress.annotations["nginx.ingress.kubernetes.io/force-ssl-redirect"] == "true" &&
      yamldecode(helm_release.this.values[1]).server.ingress.annotations["example.com/annotation"] == "example"
    )
    error_message = "Enabled ingress must render the expected hostname, TLS and protected annotations."
  }
}
