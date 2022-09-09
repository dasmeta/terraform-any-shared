resource "helm_release" "supabase" {
  name      = "supabase"
  namespace = var.namespace

  repository = "https://raw.githubusercontent.com/supabase-community/supabase-kubernetes/main/"
  chart      = "supabase"

  values = [
    "${file("${path.module}/values.yaml")}"
  ]
  wait             = false
  create_namespace = true

  // db
  set {
    name  = "database.postgresqlPassword"
    value = var.DB_PASSWORD
  }

  //studio
  set {
    name  = "studio.SUPABASE_ANON_KEY"
    value = var.ANON_KEY
  }
  set {
    name  = "studio.SUPABASE_SERVICE_KEY"
    value = var.SERVICE_KEY
  }

  //auth
  set {
    name  = "auth.environment.GOTRUE_DB_DATABASE_URL"
    value = "postgres://postgres:${var.DB_PASSWORD}@supabase-database.supabase.svc.cluster.local:5432/postgres?search_path=auth"
  }

  set {
    name  = "auth.environment.GOTRUE_JWT_SECRET"
    value = var.JWT_SECRET
  }
  set {
    name  = "auth.environment.GOTRUE_SMTP_HOST"
    value = var.SMTP_HOST
  }

  set {
    name  = "auth.environment.GOTRUE_SMTP_ADMIN_EMAIL"
    value = var.SMTP_ADMIN_EMAIL
  }

  set {
    name  = "auth.environment.GOTRUE_SMTP_USER"
    value = var.SMTP_USER
  }
  set {
    name  = "auth.environment.GOTRUE_SMTP_PASS"
    value = var.SMTP_PASS
  }
  set {
    name  = "auth.environment.GOTRUE_SMTP_SENDER_NAME"
    value = var.SMTP_SENDER_NAME
  }

  // rest
  set {
    name  = "rest.environment.PGRST_JWT_SECRET"
    value = var.JWT_SECRET
  }
  // realtime
  set {
    name  = "realtime.environment.DB_PASSWORD"
    value = var.DB_PASSWORD
  }
  set {
    name  = "realtime.environment.JWT_SECRET"
    value = var.JWT_SECRET
  }
  // storage
  set {
    name  = "storage.environment.ANON_KEY"
    value = var.ANON_KEY
  }
  set {
    name  = "storage.environment.SERVICE_KEY"
    value = var.SERVICE_KEY
  }
  set {
    name  = "storage.environment.DATABASE_URL"
    value = "postgres://postgres:${var.DB_PASSWORD}@supabase-database.supabase.svc.cluster.local:5432/postgres?search_path=auth"
  }

  // kong
  set {
    name  = "kong.credentials.anonKey"
    value = var.ANON_KEY
  }
  set {
    name  = "kong.credentials.serviceRoleKey"
    value = var.SERVICE_KEY
  }
  // urls

}


