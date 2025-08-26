locals {
  policies = concat([for item in [
    yamldecode(contains(var.policies, "bitnami-to-bitnamilegacy") ? file("${path.module}/policies/bitnami-to-bitnamilegacy.yaml") : "{}")
  ] : item if item != {}], var.custom_policies)
}
