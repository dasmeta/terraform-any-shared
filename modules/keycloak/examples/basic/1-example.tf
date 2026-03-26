module "keycloak" {
  source = "../.."

  name           = "keycloak"
  namespace      = "keycloak"
  hostname       = "keycloak.example.com"
  admin_password = "change-me-admin-password"

  database = {
    host     = "postgresql.example.internal"
    name     = "keycloak"
    username = "keycloak"
    password = "change-me-db-password"
  }
}

module "keycloak_existing_secrets" {
  source = "../.."

  name                       = "keycloak-existing-secrets"
  namespace                  = "keycloak"
  hostname                   = "sso.example.com"
  admin_password_secret_name = "keycloak-admin-password"

  ingress = {
    enabled            = true
    ingress_class_name = "nginx"
    annotations = {
      "cert-manager.io/cluster-issuer" = "letsencrypt"
    }
    tls_secret_name = "keycloak-tls"
  }

  database = {
    host                 = "postgresql.example.internal"
    name                 = "keycloak"
    username             = "keycloak"
    password_secret_name = "keycloak-db-password"
  }
}
