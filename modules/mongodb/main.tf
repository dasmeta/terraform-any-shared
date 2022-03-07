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

  values = [
    templatefile("${path.module}/values.yaml", { resources_requests_cpu = "${var.resources_requests.cpu}", resources_requests_memory = "${var.resources_requests.memory}", resources_limits_cpu = "${var.resources_limits.cpu}", resources_limits_memory = "${var.resources_limits.memory}" })
  ]

  set = [
    {
      name  = "architecture"
      value = var.architecture
    },
    {
      name  = "auth.rootPassword"
      value = var.root_password
    },
    {
      name  = "persistence.size"
      value = var.pvcsize
    },
    {
      name  = "auth.replicaSetKey"
      value = var.replicaset_key
    },
    {
      name  = "auth.existing_secret"
      value = var.existing_secret
    },
    {
      name  = "service.type"
      value = var.service_type
    }
  ]
}
