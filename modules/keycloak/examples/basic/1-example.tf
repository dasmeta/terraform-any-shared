# Test Keycloak — isolated from production
#
# - Uses namespace + Helm release name that do NOT match your main Keycloak.
# - Uses a separate PostgreSQL database (e.g. keycloak_test). Do NOT point this at the same DB
#   as production; two Keycloak instances must not share one database.
# - Uses a different hostname than prod; ALB group can match dev if each Ingress uses a distinct host.
# - `terraform destroy` in this example only removes resources in `namespace` below (and Helm release).
#
# Replace placeholders before apply. Do not commit real secrets to git.

module "keycloak" {
  source = "../.."

  name      = "keycloak"
  namespace = "keycloak"

  create_namespace = true

  chart_version = "7.1.9"
  helm_timeout  = 900

  atomic          = true
  cleanup_on_fail = true
  wait            = true

  hostname            = "keycloak.example.com"
  hostname_public_url = "https://keycloak.example.com"
  hostname_strict     = true
  proxy_mode          = "xforwarded"

  replicas    = 2
  cache_stack = "default"

  termination_grace_period_seconds = 60

  admin_username = "admin"
  admin_password = "change-me-admin-password"

  database = {
    host     = "postgresql.example.internal"
    port     = 5432
    name     = "keycloak_test"
    username = "keycloak_test_user"
    password = "change-me-db-password"
  }

  ingress = {
    enabled            = true
    ingress_class_name = "alb"
    path               = "/"
    path_type          = "Prefix"
    annotations = {
      "alb.ingress.kubernetes.io/listen-ports"    = "[{\"HTTP\":80},{\"HTTPS\":443}]"
      "alb.ingress.kubernetes.io/ssl-redirect"    = "443"
      "alb.ingress.kubernetes.io/group.name"      = "dev-ingress-keycloak-test"
      "alb.ingress.kubernetes.io/scheme"          = "internal"
      "alb.ingress.kubernetes.io/target-type"     = "ip"
      "alb.ingress.kubernetes.io/certificate-arn" = "arn:aws:acm:eu-central-1:ACCOUNT_ID:certificate/CERTIFICATE_ID"
    }
  }

  resources = {
    requests = {
      cpu    = "250m"
      memory = "512Mi"
    }
    limits = {
      cpu    = "1000m"
      memory = "1536Mi"
    }
  }

  metrics_enabled = true
  health_enabled  = true

  service_monitor = {
    enabled        = false
    interval       = "30s"
    scrape_timeout = "15s"
    labels = {
      release = "kube-prometheus-stack"
    }
  }

  event_metrics = {
    enabled = true
  }

  http_metrics_histograms = true

  log_level = "INFO"
  log_categories = {
    "org.keycloak.events" = "INFO"
  }

  http_max_queued_requests = 500
  prefer_ipv4              = true

  extra_configs = {}
}
