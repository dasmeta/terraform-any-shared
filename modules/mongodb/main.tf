module "mongodb" {
  source  = "terraform-module/release/helm"
  version = "2.7.0"

  namespace  = "default"
  repository = "https://charts.bitnami.com/bitnami"

  app = {
    name             = var.name
    chart            = "mongodb"
    version          = "11.0.5"
    create_namespace = true
    wait             = false
    recreate_pods    = false
    deploy           = 1
  }

  set = [
    {
      name  = "architecture"
      value = var.architecture
    },
    {
      name  = "auth.rootPassword"
      value = var.rootpassword
    },
    {
      name  = "persistence.size"
      value = var.pvcsize
    }
  ]
}
