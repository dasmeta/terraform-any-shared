provider "kubectl" {
  config_path      = var.kubectl_config_path == null ? null : pathexpand(var.kubectl_config_path)
  load_config_file = var.kubectl_config_path != null
}
