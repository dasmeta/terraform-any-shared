locals {
  cleanup_rbac_rules = [
    {
      apiGroups = [""]
      resources = ["namespaces"]
      verbs     = ["get", "list"]
    },
    {
      apiGroups = [""]
      resources = [
        "configmaps",
        "endpoints",
        "persistentvolumeclaims",
        "pods",
        "secrets",
        "serviceaccounts",
        "services",
      ]
      verbs = ["get", "list", "watch", "delete", "deletecollection", "patch", "update"]
    },
    {
      apiGroups = ["apps"]
      resources = ["daemonsets", "deployments", "replicasets", "statefulsets"]
      verbs     = ["get", "list", "watch", "delete", "deletecollection", "patch", "update"]
    },
    {
      apiGroups = ["batch"]
      resources = ["cronjobs", "jobs"]
      verbs     = ["get", "list", "watch", "delete", "deletecollection", "patch", "update"]
    },
    {
      apiGroups = ["autoscaling"]
      resources = ["horizontalpodautoscalers"]
      verbs     = ["get", "list", "watch", "delete", "deletecollection", "patch", "update"]
    },
    {
      apiGroups = ["networking.k8s.io", "extensions"]
      resources = ["ingresses", "networkpolicies"]
      verbs     = ["get", "list", "watch", "delete", "deletecollection", "patch", "update"]
    },
    {
      apiGroups = ["policy"]
      resources = ["poddisruptionbudgets"]
      verbs     = ["get", "list", "watch", "delete", "deletecollection", "patch", "update"]
    },
    {
      apiGroups = ["rbac.authorization.k8s.io"]
      resources = ["rolebindings", "roles"]
      verbs     = ["get", "list", "watch", "delete", "deletecollection", "patch", "update"]
    },
    {
      apiGroups = ["networking.istio.io"]
      resources = ["destinationrules", "gateways", "virtualservices"]
      verbs     = ["get", "list", "watch", "delete", "deletecollection", "patch", "update"]
    },
    {
      apiGroups = ["external-secrets.io"]
      resources = ["externalsecrets"]
      verbs     = ["get", "list", "watch", "delete", "deletecollection", "patch", "update"]
    },
  ]

  job_values = merge(
    {
      name                       = var.job_name
      schedule                   = var.schedule
      concurrencyPolicy          = var.concurrency_policy
      successfulJobsHistoryLimit = var.successful_jobs_history_limit
      failedJobsHistoryLimit     = var.failed_jobs_history_limit
      startingDeadlineSeconds    = var.starting_deadline_seconds
      suspend                    = var.suspend
      jobBackoffLimit            = var.job_backoff_limit
      ttlSecondsAfterFinished    = var.ttl_seconds_after_finished
      restartPolicy              = var.restart_policy
      imagePullPolicy            = var.image.pull_policy
      image = {
        registry   = var.image.registry
        repository = var.image.repository
        tag        = var.image.tag
      }
      command = ["/bin/sh", "/scripts/ephemeral-helm-cleanup.sh"]
      args    = var.dry_run ? ["--dry-run"] : []
      serviceAccount = {
        create      = var.service_account.create
        name        = var.service_account.name
        labels      = var.service_account.labels
        annotations = var.service_account.annotations
      }
      config = {
        enabled = true
        envFrom = false
        data = {
          "ephemeral-helm-cleanup.sh" = file("${path.module}/scripts/ephemeral-helm-cleanup.sh")
        }
      }
      env = [
        {
          name  = "NAMESPACE_NAME_PATTERN"
          value = var.namespace_name_pattern
        }
      ]
      volumes = [
        {
          name      = "cleanup-script"
          mountPath = "/scripts"
          readOnly  = true
          configMap = {
            name        = var.job_name
            defaultMode = "0555"
          }
        }
      ]
      rbac = {
        create      = var.rbac.create
        clusterWide = var.rbac.cluster_wide
        name        = var.rbac.name
        rules       = length(var.rbac.rules) > 0 ? var.rbac.rules : local.cleanup_rbac_rules
      }
      resources      = var.resources
      podAnnotations = var.pod_annotations
      nodeSelector   = var.node_selector
      tolerations    = var.tolerations
      labels         = var.labels
    },
    var.extra_job_values
  )

  helm_values = merge(
    {
      jobs = [local.job_values]
    },
    var.extra_values
  )
}
