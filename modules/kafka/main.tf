module "kafka" {
  source  = "terraform-module/release/helm"
  version = "2.7.0"

  namespace  = var.namespace
  repository = "https://charts.bitnami.com/bitnami"

  app = {
    name             = var.name
    version          = var.chart_version
    chart            = "kafka"
    create_namespace = var.create_namespace
    force_update     = var.force_update
    wait             = var.wait
    recreate_pods    = var.recreate_pods
    deploy           = var.deploy
  }
  values = [
    templatefile("${path.module}/values.yaml", { resources_requests_cpu = "${var.resources_requests.cpu}", resources_requests_memory = "${var.resources_requests.memory}", resources_limits_cpu = "${var.resources_limits.cpu}", resources_limits_memory = "${var.resources_limits.memory}" })
  ]

  set = var.helm_set
}

module "kafka_ui" {
  count = var.enable_kafka_ui ? 1 : 0

  source  = "terraform-module/release/helm"
  version = "2.7.0"

  namespace  = var.namespace
  repository = "https://provectus.github.io/kafka-ui"

  app = {
    name             = "${var.name}-ui"
    version          = var.kafka_ui_chart_version
    chart            = "kafka-ui"
    create_namespace = "false"
    force_update     = var.force_update
    wait             = var.wait
    recreate_pods    = var.recreate_pods
    deploy           = var.deploy
  }

  set = [
    {
      name  = "KAFKA_CLUSTERS_0_NAME"
      value = var.kafka_cluster_0_name
    },
    {
      name  = "KAFKA_CLUSTERS_0_BOOTSTRAPSERVERS"
      value = var.kafka_cluster_0_bootstrapservers
    },
    {
      name  = "KAFKA_CLUSTERS_0_ZOOKEEPER"
      value = var.kafka_cluster_0_zookeeper
    }
  ]
}
