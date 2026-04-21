# Configure providers in 0-setup.tf before plan/apply.
#
# For production, prefer use_existing_admin_secret=true and manage argocd-secret
# out-of-band (e.g. ExternalSecret -> AWS Secrets Manager).

module "argocd" {
  source = "../.."

  name      = "argocd"
  namespace = "argocd"

  hostname = "argocd.example.com"

  ingress = {
    enabled   = true
    path      = "/"
    path_type = "Prefix"
    annotations = {
      "alb.ingress.kubernetes.io/listen-ports" = "[{\"HTTP\":80},{\"HTTPS\":443}]"
      "alb.ingress.kubernetes.io/ssl-redirect" = "443"
      "alb.ingress.kubernetes.io/group.name"   = "my-existing-alb-group"
      "alb.ingress.kubernetes.io/scheme"       = "internal"
      "alb.ingress.kubernetes.io/target-type"  = "ip"
      #"alb.ingress.kubernetes.io/certificate-arn" = "arn:aws:acm:region:account:certificate/..."
    }
  }

  # Recommended: manage argocd-secret outside Terraform (e.g. ExternalSecret -> AWS Secrets Manager).
  use_existing_admin_secret = true
  create_namespace = true
  
  # generate a new password and paste for admin user here before apply with bcrypt hash
  #admin_password_bcrypt = "$2b$12$..."
}
