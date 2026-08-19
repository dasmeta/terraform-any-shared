module "namespace" {
  source = "../.."

  name = "example-platform"

  labels = {
    "app.kubernetes.io/part-of" = "example-platform"
  }

  annotations = {
    "example.com/owner" = "platform-team"
  }
}
