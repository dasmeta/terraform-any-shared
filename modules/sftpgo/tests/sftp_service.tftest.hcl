mock_provider "helm" {}
mock_provider "kubernetes" {
  mock_resource "kubernetes_service_v1" {
    defaults = {
      spec = { external_traffic_policy = "" }
    }
  }
}

variables {
  admin = { password = "test-admin-password" }
  s3_storage = {
    bucket        = "test-sftpgo"
    region        = "eu-central-1"
    access_key    = "test-access-key"
    access_secret = "test-secret"
  }
  bootstrap_users = [{ username = "test-user", password = "test-password" }]
}

run "local_load_balancer_preserves_service_contract" {
  command = plan
  variables {
    sftp_service = {
      enabled                     = true
      port                        = 36220
      external_traffic_policy     = "Local"
      load_balancer_source_ranges = ["203.0.113.0/24"]
      annotations = {
        "service.beta.kubernetes.io/aws-load-balancer-attributes" = "load_balancing.cross_zone.enabled=true"
      }
    }
  }
  assert {
    condition     = kubernetes_service_v1.sftp[0].spec[0].external_traffic_policy == "Local"
    error_message = "The SFTP LoadBalancer must use the requested Local traffic policy."
  }
  assert {
    condition = (
      kubernetes_service_v1.sftp[0].spec[0].load_balancer_class == "service.k8s.aws/nlb" &&
      kubernetes_service_v1.sftp[0].spec[0].load_balancer_source_ranges == toset(["203.0.113.0/24"]) &&
      kubernetes_service_v1.sftp[0].spec[0].selector["app.kubernetes.io/instance"] == "sftpgo" &&
      length(kubernetes_service_v1.sftp[0].spec[0].port) == 1 &&
      kubernetes_service_v1.sftp[0].spec[0].port[0].port == 36220 &&
      kubernetes_service_v1.sftp[0].spec[0].port[0].target_port == "sftp" &&
      kubernetes_service_v1.sftp[0].metadata[0].annotations["service.beta.kubernetes.io/aws-load-balancer-attributes"] == "load_balancing.cross_zone.enabled=true"
    )
    error_message = "Local routing must preserve NLB class, source restrictions, selectors, annotations and the SFTP-only port."
  }
}

run "default_policy_remains_cluster" {
  command = plan
  variables { sftp_service = { enabled = true } }
  assert {
    condition     = kubernetes_service_v1.sftp[0].spec[0].external_traffic_policy == "Cluster"
    error_message = "Existing consumers must retain the Cluster policy."
  }
}

run "explicit_cluster_policy" {
  command = plan
  variables { sftp_service = { enabled = true, external_traffic_policy = "Cluster" } }
  assert {
    condition     = kubernetes_service_v1.sftp[0].spec[0].external_traffic_policy == "Cluster"
    error_message = "Explicit Cluster must be supported."
  }
}

run "local_node_port" {
  command = plan
  variables { sftp_service = { enabled = true, type = "NodePort", external_traffic_policy = "Local" } }
  assert {
    condition     = kubernetes_service_v1.sftp[0].spec[0].external_traffic_policy == "Local"
    error_message = "NodePort services must support Local routing."
  }
}

run "cluster_ip_omits_external_policy" {
  # Resolve the computed omitted field using only the mocked provider.
  command = apply
  variables { sftp_service = { enabled = true, type = "ClusterIP" } }
  assert {
    condition     = coalesce(kubernetes_service_v1.sftp[0].spec[0].external_traffic_policy, "omitted") == "omitted"
    error_message = "ClusterIP services must not receive an external traffic policy."
  }
}

run "disabled_service_stays_disabled" {
  command = plan
  assert {
    condition     = length(kubernetes_service_v1.sftp) == 0
    error_message = "The module must not create an SFTP Service by default."
  }
}

run "reject_invalid_policy" {
  command = plan
  variables { sftp_service = { enabled = true, external_traffic_policy = "local" } }
  expect_failures = [var.sftp_service]
}

run "reject_local_cluster_ip" {
  command = plan
  variables { sftp_service = { enabled = true, type = "ClusterIP", external_traffic_policy = "Local" } }
  expect_failures = [var.sftp_service]
}
