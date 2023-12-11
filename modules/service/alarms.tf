module "cw_alerts" {
  count = var.alarms.enabled ? 1 : 0

  source  = "dasmeta/monitoring/aws//modules/alerts"
  version = "1.3.5"

  sns_topic = var.alarms.sns_topic

  alerts = [
    // Restarts
    {
      name   = "${var.name} has too many restarts in ${var.cluster_name}"
      source = "ContainerInsights/pod_number_of_container_restarts"
      filters = {
        ClusterName = var.cluster_name,
        Deployment  = var.name,
        Namespace   = var.namespace
      }
      period    = try(var.alarms.custom_values.restarts.period, 300),
      statistic = try(var.alarms.custom_values.restarts.statistic, "max"),
      threshold = try(var.alarms.custom_values.restarts.threshold, 2)
      equation  = try(var.alarms.custom_values.restarts.equation, "gte")
    },
    // Replicas
    {
      name   = "${var.name} has 0 available replicas in ${var.cluster_name}"
      source = "ContainerInsights/kube_deployment_spec_replicas"
      filters = {
        ClusterName = var.cluster_name,
        Deployment  = var.name,
        Namespace   = var.namespace
      }
      period    = try(var.alarms.custom_values.replicas.period, 300),
      statistic = try(var.alarms.custom_values.replicas.statistic, "avg"),
      threshold = try(var.alarms.custom_values.replicas.threshold, 0),
      equation  = try(var.alarms.custom_values.replicas.equation, "lte")
    },
    // CPU
    {
      name   = "${var.name} have have cpu problem in ${var.cluster_name}",
      source = "ContainerInsights/pod_cpu_utilization",
      filters = {
        PodName     = var.name,
        ClusterName = var.cluster_name,
        Namespace   = var.namespace
      },
      period    = try(var.alarms.custom_values.cpu.period, 300),
      statistic = try(var.alarms.custom_values.cpu.statistic, "avg"),
      threshold = try(var.alarms.custom_values.cpu.threshold, 90)
      equation  = try(var.alarms.custom_values.cpu.equation, "gte")
    },
    // MEMORY
    {
      name   = "${var.name} have memory problem in ${var.cluster_name}",
      source = "ContainerInsights/pod_memory_utilization",
      filters = {
        PodName     = var.name,
        ClusterName = var.cluster_name,
        Namespace   = var.namespace
      },
      period    = try(var.alarms.custom_values.memory.period, 300),
      statistic = try(var.alarms.custom_values.memory.statistic, "avg"),
      threshold = try(var.alarms.custom_values.memory.threshold, 90)
      equation  = try(var.alarms.custom_values.memory.equation, "gte")
    },
  ]

  depends_on = [
    helm_release.service
  ]
}
