module "this" {
  source = "../../"

  build_job_limits = {
    "cpu" : "15",
    "memory" : "24Gi"
  }

  build_job_requests = {
    "cpu" : "13",
    "memory" : "16Gi"
  }
  cache = {
    "path" : "/tmp/gitlab/cache",
    "shared" : true,
    "type" : "pvc"
  }
  namespace                 = "gitlab-runner"
  runner_name               = "gitlab-runner"
  runner_registration_token = "glrt-4szkC5UCPy_NAyx47yz5"
  runner_tags               = "k8s-runner"
}
