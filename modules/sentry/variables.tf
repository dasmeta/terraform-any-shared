variable "name" {
  description = "The name of helm release."
  type        = string
  default     = "sentry"
}

variable "chart_version" {
  type        = string
  default     = "27.4.2"
  description = "The app chart version to use"
}

variable "namespace" {
  description = "The namespace to install app helm. The doc recommends to have kyverno installed in its own namespace so before changing this check docs."
  type        = string
  default     = "sentry"
}

variable "create_namespace" {
  type        = bool
  default     = true
  description = "Create namespace if requested"
}

variable "wait" {
  type        = bool
  default     = true
  description = "Whether wait to get the workload run successfully"
}

variable "atomic" {
  type        = bool
  default     = false
  description = "Whether auto rollback if helm install fails"
}

variable "default_configs" {
  type = any
  default = {
    "sentry" : {
      "image" : {
        "repository" : "getsentry/sentry"
        "tag" : "24.8.0"
      },
      "web" : {
        "replicas" : 1
        "resources" : {
          "requests" : {
            "cpu" : "500m"
            "memory" : "1Gi"
          }
          "limits" : {
            "cpu" : "700m"
            "memory" : "1700Mi"
          }
        }
        "env" : [
          {
            "name" : "UWSGI_WORKERS"
            "value" : "2"
          }
        ]
        "readinessProbe" : {
          "initialDelaySeconds" : "120"
        }
        "livenessProbe" : {
          "initialDelaySeconds" : "180"
        }
      },
      "worker" : {
        "replicas" : 1
      },
      "cron" : {
        "replicas" : 1
      },
      "postProcessForwarder" : {
        "replicas" : 1
      },
      "resources" : {
        "limits" : {
          "cpu" : "1500m",
          "memory" : "1500Mi"
        },
        "requests" : {
          "cpu" : "1",
          "memory" : "1Gi"
        }
      },
      "features" : {
        "enableFeedback" : true
        "system" : {
          "feedback" : true,
          "replays" : false
        },
        "organizations" : {
          "performance-view" : true,
          "session-replay" : false
        }
      }
    },
    "postgresql" : {
      "enabled" : true,
      "auth" : {
        "username" : "sentry",
        "password" : "sentry",
        "database" : "sentry"
      }
    },
    "redis" : {
      "enabled" : true,
      "architecture" : "standalone",
      "master" : {
        "persistence" : {
          "enabled" : true
        }
      }
    },
    "zookeeper" : {
      "enabled" : true
    },
    "kafka" : {
      "enabled" : true,
    },
    "symbolicator" : {
      "enabled" : true,
    },
    "snuba" : {
      "api" : {
        "replicas" : 1
      },
      "consumer" : {
        "replicas" : 1
      },
      "outcomesConsumer" : {
        "replicas" : 1
      },
      "replacer" : {
        "replicas" : 1
      },
      "sessionsConsumer" : {
        "replicas" : 1
      }
    },
    "clickhouse" : {
      "enabled" : true,
    },
    "relay" : {
      "enabled" : true
    }
    "filestore" : {
      "backend" : "S3"
      "s3" : {
        "bucketName" : "Sentry" # Additional S3 configuration needs to be supplied for the filestore to work
      }
    }
  }

  description = "The default values config to pass to helm chart. NOTE: that if you need to change just one field you will need to pass all configs and that field cha changed or you can pass you custom config within var.extra_configs"
}

variable "extra_configs" {
  type        = any
  default     = {}
  description = "Configs to pass and override helm values.yaml defaults and var.default_configs if needed more fine control. for more info check https://artifacthub.io/packages/helm/kyverno/kyverno?modal=values"
}

variable "minio_configs" {
  type = object({
    enabled       = optional(bool, true)
    name          = optional(string, "sentry-minio")
    extra_configs = optional(any, {})
    chart_version = optional(string, "5.4.0")
  })
  default     = {}
  description = "Configuration for minio deployment"
}
