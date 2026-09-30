mock_provider "helm" {}
mock_provider "kubernetes" {}

variables {
  admin = { password = "test-admin-password" }
  s3_storage = {
    bucket        = "test-sftpgo"
    region        = "eu-central-1"
    access_key    = "test-access-key"
    access_secret = "test-secret"
  }
  bootstrap_users = [{ username = "test-user", password = "test-password" }]
}

run "trusted_proxy_preserves_session_and_bootstrap" {
  command = plan

  variables {
    web_proxy = {
      proxy_allowed = ["10.0.1.0/24", "10.0.2.0/24"]
    }
    web_session = {
      signing_passphrase = "test-stable-signing-passphrase"
      cookie_lifetime    = 600
    }
    extra_values = { ui = { ingress = { enabled = true } } }
  }

  assert {
    condition = (
      yamldecode(helm_release.this.values[0]).config.httpd.bindings[0].proxy_allowed == ["10.0.1.0/24", "10.0.2.0/24"] &&
      yamldecode(helm_release.this.values[0]).config.httpd.bindings[0].client_ip_proxy_header == "X-Forwarded-For" &&
      yamldecode(helm_release.this.values[0]).config.httpd.bindings[0].client_ip_header_depth == 0
    )
    error_message = "The HTTP binding must trust only the supplied proxies and use the rightmost forwarded address."
  }

  assert {
    condition = (
      yamldecode(helm_release.this.values[0]).config.httpd.signing_passphrase == "test-stable-signing-passphrase" &&
      yamldecode(helm_release.this.values[0]).config.httpd.cookie_lifetime == 600 &&
      yamldecode(helm_release.this.values[0]).config.httpd.token_validation == 0 &&
      yamldecode(helm_release.this.values[0]).config.common.setstat_mode == 2 &&
      yamldecode(helm_release.this.values[0]).config.data_provider.create_default_admin &&
      yamldecode(helm_release.this.values[0]).ui.ingress.enabled
    )
    error_message = "Proxy configuration must preserve session, bootstrap, storage and ingress settings."
  }

  assert {
    condition = (
      yamldecode(helm_release.this.values[0]).config.httpd.bindings[0].port == 8080 &&
      yamldecode(helm_release.this.values[0]).config.httpd.bindings[0].enable_web_admin &&
      yamldecode(helm_release.this.values[0]).config.httpd.bindings[0].enable_web_client &&
      yamldecode(helm_release.this.values[0]).config.httpd.bindings[0].enable_rest_api
    )
    error_message = "Proxy configuration must preserve WebAdmin, WebClient and the bootstrap REST API on port 8080."
  }
}

run "default_configuration_is_unchanged" {
  command = plan
  assert {
    condition     = !can(yamldecode(helm_release.this.values[0]).config.httpd)
    error_message = "Omitting both HTTP inputs must leave HTTP defaults to SFTPGo."
  }
}

run "session_without_proxy_is_unchanged" {
  command = plan
  variables {
    web_session = { signing_passphrase = "test-signing-passphrase" }
  }
  assert {
    condition = (
      !can(yamldecode(helm_release.this.values[0]).config.httpd.bindings) &&
      yamldecode(helm_release.this.values[0]).config.httpd.token_validation == 0 &&
      yamldecode(helm_release.this.values[0]).config.httpd.cookie_lifetime == 720
    )
    error_message = "Session-only consumers must retain their original configuration."
  }
}

run "proxy_without_session_and_custom_chain" {
  command = plan
  variables {
    web_proxy = {
      proxy_allowed          = ["2001:db8::/64"]
      client_ip_proxy_header = "X-Real-IP"
      client_ip_header_depth = 1
    }
  }
  assert {
    condition = (
      !can(yamldecode(helm_release.this.values[0]).config.httpd.signing_passphrase) &&
      yamldecode(helm_release.this.values[0]).config.httpd.bindings[0].client_ip_proxy_header == "X-Real-IP" &&
      yamldecode(helm_release.this.values[0]).config.httpd.bindings[0].client_ip_header_depth == 1
    )
    error_message = "Proxy configuration must work independently of optional web_session settings."
  }
}

run "reject_empty_trust" {
  command = plan
  variables { web_proxy = { proxy_allowed = [] } }
  expect_failures = [var.web_proxy]
}

run "reject_invalid_cidr" {
  command = plan
  variables { web_proxy = { proxy_allowed = ["not-a-cidr"] } }
  expect_failures = [var.web_proxy]
}

run "reject_null_trust" {
  command = plan
  variables { web_proxy = { proxy_allowed = null } }
  expect_failures = [var.web_proxy]
}

run "reject_null_cidr" {
  command = plan
  variables { web_proxy = { proxy_allowed = [null] } }
  expect_failures = [var.web_proxy]
}

run "reject_universal_trust" {
  command = plan
  variables { web_proxy = { proxy_allowed = ["0.0.0.0/0", "::/0"] } }
  expect_failures = [var.web_proxy]
}

run "reject_blank_header" {
  command = plan
  variables { web_proxy = { proxy_allowed = ["10.0.1.0/24"], client_ip_proxy_header = " " } }
  expect_failures = [var.web_proxy]
}

run "reject_leftmost_trust" {
  command = plan
  variables { web_proxy = { proxy_allowed = ["10.0.1.0/24"], client_ip_header_depth = -1 } }
  expect_failures = [var.web_proxy]
}

run "reject_fractional_depth" {
  command = plan
  variables { web_proxy = { proxy_allowed = ["10.0.1.0/24"], client_ip_header_depth = 0.5 } }
  expect_failures = [var.web_proxy]
}
