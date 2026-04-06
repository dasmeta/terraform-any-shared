# EKS + RDS. Configure providers in 0-setup.tf before plan/apply.
#
# WARNING: This file may contain secrets for local plan/apply. Do not commit real
# passwords to git — use terraform.tfvars (gitignored) or *_secret_name in production.

module "keycloak" {
  source = "../.."

  name      = "keycloak"
  namespace = "keycloak"

  hostname = "localhost"
  # hostname = "keycloak-keycloakx-http.keycloak.svc.cluster.local" # Host header / KC_HOSTNAME for in-cluster testing
  hostname_strict = false

  admin_username = "admin"
  admin_password = "change-me-admin-password"

  database = {
    host     = "postgresql.example.internal"
    port     = 5432
    name     = "keycloak"
    username = "keycloak"
    password = "change-me-db-password"
  }

  ingress = {
    enabled            = true
    ingress_class_name = "alb"
    annotations = {
      "alb.ingress.kubernetes.io/group.name"  = "my-existing-alb-group"
      "alb.ingress.kubernetes.io/target-type" = "ip"
      "alb.ingress.kubernetes.io/scheme"      = "internal"
      # "alb.ingress.kubernetes.io/certificate-arn" = "arn:aws:acm:region:account:certificate/..."
      # "alb.ingress.kubernetes.io/listen-ports"    = "[{\"HTTPS\":443}]"
      # "alb.ingress.kubernetes.io/ssl-redirect"    = "443"
    }
    # tls_secret_name = "keycloak-tls"
  }

  # If ALB is not AWS LBC: ingress = { enabled = false } and wire Service to target group.
}
