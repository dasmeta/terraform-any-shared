module "sftpgo" {
  source = "../../"

  name      = "sftpgo-test"
  namespace = "sftpgo-test"

  create_namespace = false
  wait             = false

  s3_storage = {
    bucket        = "test-sftpgo"
    region        = "eu-central-1"
    access_key    = "test-access-key"
    access_secret = "test-s3-secret"
  }

  admin = {
    username = "admin"
    password = "test-admin-password"
  }

  web_session = {
    signing_passphrase = "test-sftpgo-web-session-signing-passphrase"
    cookie_lifetime    = 720
    token_validation   = 0
  }

  bootstrap_users = [
    {
      username                = "test-user"
      password                = "test-user-password"
      key_prefix              = "test-user/"
      require_password_change = false
    }
  ]

  persistence = {
    enabled = true
    storage = "1Gi"
  }

  sftp_service = {
    enabled = true
    type    = "LoadBalancer"
    port    = 22
    annotations = {
      "service.beta.kubernetes.io/aws-load-balancer-type"   = "nlb"
      "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internal"
    }
  }

  resources = {
    requests = {
      cpu    = "100m"
      memory = "256Mi"
    }
    limits = {
      cpu    = "250m"
      memory = "512Mi"
    }
  }
}
