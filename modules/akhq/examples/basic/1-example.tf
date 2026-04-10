# Prerequisites: Kubernetes cluster, reachable Kafka bootstrap, and optional ingress controller.
# Prefer security.basic_auth_password from terraform.tfvars (gitignored) or ExternalSecret workflows.

module "akhq" {
  source = "../.."

  name      = "akhq"
  namespace = "akhq"

  hostname               = "akhq.example.com"
  network_policy_enabled = false

  security = {
    enabled             = true
    basic_auth_username = "admin"
    basic_auth_password = "change-me-akhq-ui-password"
  }

  kafka = {
    connection_name   = "example-cluster"
    bootstrap_servers = "kafka-broker.example.internal:9092"
  }

  ingress = {
    enabled            = true
    ingress_class_name = "alb"
    path               = "/"
    path_type          = "Prefix"
    annotations = {
      "alb.ingress.kubernetes.io/group.name"  = "example-ingress"
      "alb.ingress.kubernetes.io/scheme"      = "internal"
      "alb.ingress.kubernetes.io/target-type" = "ip"
    }
  }

  resources = {
    requests = {
      cpu    = "100m"
      memory = "256Mi"
    }
    limits = {
      cpu    = "500m"
      memory = "512Mi"
    }
  }
}
