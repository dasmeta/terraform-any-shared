module "akhq" {
  source = "../../"

  hostname               = "akhq.dev.example.com"
  network_policy_enabled = false
  namespace              = "dev"
  create_namespace       = false

  security = {
    enabled              = true
    basic_auth_username  = "admin"
    basic_auth_password  = "change-me"
    micronaut_jwt_secret = "change-me-32chars-min-random-secret-for-testing"
  }

  kafka = {
    connection_name   = "kafka"
    bootstrap_servers = "b-1.examplemsk.example.com:9096,b-2.examplemsk.example.com:9096"
    properties = {
      "security.protocol" = "SASL_SSL"
      "sasl.mechanism"    = "SCRAM-SHA-512"
    }
  }

  kafka_scram_username = var.kafka_scram_username
  kafka_scram_password = var.kafka_scram_password

  ingress = {
    enabled            = true
    ingress_class_name = "alb"
    annotations = {
      "alb.ingress.kubernetes.io/listen-ports"    = "[{\"HTTP\":80},{\"HTTPS\":443}]"
      "alb.ingress.kubernetes.io/ssl-redirect"    = "443"
      "alb.ingress.kubernetes.io/group.name"      = "example-ingress"
      "alb.ingress.kubernetes.io/scheme"          = "internal"
      "alb.ingress.kubernetes.io/target-type"     = "ip"
      "alb.ingress.kubernetes.io/certificate-arn" = "arn:aws:acm:eu-central-1:000000000000:certificate/00000000-0000-0000-0000-000000000000"
    }
  }
}
