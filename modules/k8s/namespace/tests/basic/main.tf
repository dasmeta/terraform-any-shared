module "namespace" {
  source = "../.."

  name = "test-platform"

  labels = {
    "app.kubernetes.io/part-of" = "test-platform"
  }
}

output "namespace_name" {
  value = module.namespace.namespace_name
}

output "namespace_id" {
  value = module.namespace.namespace_id
}
