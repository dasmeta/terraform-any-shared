# EKS + RDS. Ingress joins an existing ALB created by AWS Load Balancer Controller
# (same alb.ingress.kubernetes.io/group.name as your other Ingresses).
#
# Before apply:
# - Configure Kubernetes/Helm providers in 0-setup.tf (kubeconfig or aws_eks_* auth).
# - Ensure RDS allows Postgres from your EKS network (security groups).
#
# Do not commit real passwords or real database endpoints in examples.
# Prefer existing Secrets, or use a local `terraform.tfvars` (gitignored).

module "keycloak" {
  source = "../.."

  name      = "keycloak"
  namespace = "keycloak"
  # Use your real hostname here for ingress traffic.
  # For local testing with `kubectl port-forward`, you can use "localhost" and keep hostname_strict=false.
  hostname        = "localhost"
  hostname_strict = false
  admin_username  = "admin"
  # Example-only placeholder. Use `admin_password_secret_name` in real setups.
  admin_password = "change-me-admin-password"

  database = {
    # Example-only placeholder. Prefer `password_secret_name` in real setups.
    host     = "postgresql.example.internal"
    port     = 5432
    name     = "keycloak"
    username = "keycloak"
    password = "change-me-db-password"
  }

  # Replace group.name with the same value as your existing Ingress (kubectl get ingress -A -o yaml | grep group.name).
  ingress = {
    enabled            = true
    ingress_class_name = "alb"
    annotations = {
      # Must match the group.name used by your existing Ingress resources (AWS LBC).
      "alb.ingress.kubernetes.io/group.name"  = "my-existing-alb-group"
      "alb.ingress.kubernetes.io/target-type" = "ip"
      "alb.ingress.kubernetes.io/scheme"      = "internal"
      # "alb.ingress.kubernetes.io/certificate-arn" = "arn:aws:acm:region:account:certificate/..."
      # "alb.ingress.kubernetes.io/listen-ports"    = "[{\"HTTPS\":443}]"
      # "alb.ingress.kubernetes.io/ssl-redirect"    = "443"
    }
    # tls_secret_name = "keycloak-tls"
  }

  # --- If your ALB is NOT from AWS LBC (standalone ALB in AWS): use Service + target group instead ---
  # ingress = { enabled = false }
  # Then: kubectl get svc -n keycloak and register that Service with your ALB / TargetGroupBinding.
}

# Production-style alternative: reference existing Secrets (no raw passwords in Terraform).
# Create Secrets `keycloak-admin-password` and `keycloak-db-password` in namespace `keycloak` first.
#
# module "keycloak" {
#   source = "../.."
#
#   name                       = "keycloak"
#   namespace                  = "keycloak"
#   hostname                   = "keycloak.internal.example.com"
#   admin_password_secret_name = "keycloak-admin-password"
#
#   database = {
#     host                 = "mydb.xxxxxxxxxxxx.us-east-1.rds.amazonaws.com"
#     name                 = "keycloak"
#     username             = "keycloak"
#     password_secret_name = "keycloak-db-password"
#   }
#
#   ingress = {
#     enabled            = true
#     ingress_class_name = "alb"
#     annotations = {
#       "alb.ingress.kubernetes.io/group.name"  = "my-existing-alb-group"
#       "alb.ingress.kubernetes.io/target-type" = "ip"
#       "alb.ingress.kubernetes.io/scheme"      = "internal"
#     }
#   }
# }
































# module "keycloak" {
#   source = "../.."

#   name           = "keycloak"
#   namespace      = "keycloak"
#   hostname       = "keycloak.example.com"
#   admin_password = "change-me-admin-password"

#   database = {
#     host     = "postgresql.example.internal"
#     name     = "keycloak"
#     username = "keycloak"
#     password = "change-me-db-password"
#   }
# }

# module "keycloak_existing_secrets" {
#   source = "../.."

#   name                       = "keycloak-existing-secrets"
#   namespace                  = "keycloak"
#   hostname                   = "sso.example.com"
#   admin_password_secret_name = "keycloak-admin-password"

#   ingress = {
#     enabled            = true
#     ingress_class_name = "nginx"
#     annotations = {
#       "cert-manager.io/cluster-issuer" = "letsencrypt"
#     }
#     tls_secret_name = "keycloak-tls"
#   }

#   database = {
#     host                 = "postgresql.example.internal"
#     name                 = "keycloak"
#     username             = "keycloak"
#     password_secret_name = "keycloak-db-password"
#   }
# }
