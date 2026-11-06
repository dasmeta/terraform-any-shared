module "sftpgo" {
  source = "../.."

  name             = "sftpgo"
  namespace        = "sftpgo"
  create_namespace = true

  chart_repository = "oci://ghcr.io/sftpgo/helm-charts"
  chart            = "sftpgo"
  chart_version    = "0.45.0"

  atomic          = true
  cleanup_on_fail = true
  wait            = true
  timeout         = 900

  replica_count = 1

  # Opt in to planned transfer draining; coordinate the NLB drain timeout too.
  shutdown = {
    grace_time                       = 300
    termination_grace_period_seconds = 330
  }

  s3_storage = {
    bucket        = "example-dev-sftpgo"
    region        = var.region
    access_key    = var.sftpgo_s3_access_key
    access_secret = var.sftpgo_s3_access_secret
  }

  admin = {
    enabled  = true
    username = "admin"
    password = var.sftpgo_admin_password
  }

  web_session = {
    signing_passphrase = var.sftpgo_web_session_signing_passphrase
    cookie_lifetime    = 720
    token_validation   = 0
  }

  # Replace these CIDRs with the trusted reverse proxy subnets in your environment.
  web_proxy = {
    proxy_allowed          = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
    client_ip_proxy_header = "X-Forwarded-For"
    client_ip_header_depth = 0
  }

  bootstrap_users = [
    {
      username                = "demo-user"
      password                = var.sftpgo_demo_user_password
      key_prefix              = "demo-user/"
      require_password_change = true
    }
  ]

  image_pull_secrets = [
    {
      name = "docker-registry-auth"
    }
  ]

  strategy = {
    type = "Recreate"
  }

  bootstrap_image = "python:3.12-alpine"

  persistence = {
    enabled            = true
    storage_class_name = "gp2"
    access_modes       = ["ReadWriteOnce"]
    storage            = "10Gi"
  }

  sftp_service = {
    enabled                 = true
    type                    = "LoadBalancer"
    port                    = 22
    external_traffic_policy = "Local"
    annotations = {
      "service.beta.kubernetes.io/aws-load-balancer-type"       = "nlb"
      "service.beta.kubernetes.io/aws-load-balancer-scheme"     = "internal"
      "service.beta.kubernetes.io/aws-load-balancer-attributes" = "load_balancing.cross_zone.enabled=true"
    }
  }

  extra_values = {
    ui = {
      ingress = {
        enabled   = true
        className = "alb"
        annotations = {
          "kubernetes.io/ingress.class"            = "alb"
          "alb.ingress.kubernetes.io/target-type"  = "ip"
          "alb.ingress.kubernetes.io/listen-ports" = "[{\"HTTPS\":443}]"
          "alb.ingress.kubernetes.io/scheme"       = "internal"
          "alb.ingress.kubernetes.io/group.name"   = "example-main"
        }
        hosts = [
          {
            host = "sftpgo.dev.example.com"
            paths = [
              {
                path     = "/"
                pathType = "Prefix"
              }
            ]
          }
        ]
      }
    }
  }

  resources = {
    requests = {
      cpu    = "250m"
      memory = "512Mi"
    }
    limits = {
      cpu    = "500m"
      memory = "1Gi"
    }
  }
}
