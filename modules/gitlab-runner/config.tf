locals {
  config = <<EOF
[[runners]]
%{if var.cache.type == "local"~}
  cache_dir = "${var.local_cache_dir}"
%{~else~}
  [runners.cache]
    Type = "${var.cache.type}"
    Path = "${var.cache.path}"
    Shared = ${var.cache.shared}
%{~endif}
  [runners.kubernetes]
    cpu_limit = "${var.build_job_limits.cpu}"
    cpu_request = "${var.build_job_requests.cpu}"
    memory_limit = "${var.build_job_limits.memory}"
    memory_request = "${var.build_job_requests.memory}"
  %{~if var.build_job_default_container_image != null~}
    image = "${var.build_job_default_container_image}"
  %{~endif~}
    service_account = "${var.service_account}"
    image_pull_secrets = ${jsonencode(var.image_pull_secrets)}
    privileged      = ${var.build_job_privileged}
    poll_interval = ${var.build_job_poll.interval}
    poll_timeout = ${var.build_job_poll.timeout}
    [runners.kubernetes.affinity]
    [runners.kubernetes.node_selector]
    %{~for key, value in var.build_job_node_selectors~}
      "${key}" = "${value}"
    %{~endfor~}
    [runners.kubernetes.node_tolerations]
    %{~for key, value in var.build_job_node_tolerations~}
      "${key}" = "${value}"
    %{~endfor~}
    [runners.kubernetes.pod_labels]
    %{~for key, value in var.build_job_pod_labels~}
      "${key}" = "${value}"
    %{~endfor~}
    [runners.kubernetes.pod_annotations]
    %{~for key, value in var.build_job_pod_annotations~}
      "${key}" = "${value}"
    %{~endfor~}
    [runners.kubernetes.pod_security_context]
    %{~if var.build_job_mount_docker_socket~}
      fs_group = ${var.docker_fs_group}
    %{~endif~}
    %{~if var.build_job_run_container_as_user != null~}
      run_as_user: ${var.build_job_run_container_as_user}
    %{~endif~}
    [runners.kubernetes.volumes]
    %{~if var.build_job_mount_docker_socket~}
      [[runners.kubernetes.volumes.host_path]]
        name = "docker-socket"
        mount_path = "/var/run/docker.sock"
        read_only = true
        host_path = "/var/run/docker.sock"
    %{~endif~}
    %{~if var.cache.type == "local"~}
      [[runners.kubernetes.volumes.host_path]]
        name = "cache"
        mount_path = "${var.local_cache_dir}"
        host_path = "${var.local_cache_dir}"
    %{~endif~}
    %{~if var.cache.type == "pvc"~}
      [[runners.kubernetes.volumes.pvc]]
        name = "cache"
        mount_path = "${var.local_cache_dir}"
    %{~endif~}
    %{~if lookup(var.build_job_secret_volumes, "name", null) != null~}
      [[runners.kubernetes.volumes.secret]]
        name = ${lookup(var.build_job_secret_volumes, "name", "")}
        mount_path = ${lookup(var.build_job_secret_volumes, "mount_path", "")}
        read_only = ${lookup(var.build_job_secret_volumes, "read_only", "")}
        [runners.kubernetes.volumes.secret.items]
          %{~for key, value in lookup(var.build_job_secret_volumes, "items", {})~}
            ${key} = ${value}
          %{~endfor~}
    %{~endif~}
%{~if var.docker_cert.enabled~}
  [[runners.kubernetes.volumes.empty_dir]]
    name = ${lookup(var.docker_cert, "name", "\"docker-certs\"")}
    mount_path = ${lookup(var.docker_cert, "mount_path", "\"/certs/client\"")}
    medium = ${lookup(var.docker_cert, "medium", "\"Memory\"")}
%{~endif~}
EOF
}
