resource "helm_release" "vpa" {
  count      = var.create_vpa_server ? 1 : 0
  name       = "goldilocks"
  version    = "0.5.0"
  repository = "https://charts.fairwinds.com/stable"
  chart      = "vpa"
}

resource "helm_release" "metric_server" {
  count      = var.create_metric_server ? 1 : 0
  name       = "metrics-server"
  version    = "5.8.5"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"
}
resource "kubernetes_manifest" "create_namespace" {
  manifest = {
    "apiVersion" = "v1"
    "kind"       = "Namespace"
    "metadata" = {
      "name" = "goldilocks"
    }
  }
}

resource "null_resource" "vpa_configure" {
  for_each = var.namespaces

  provisioner "local-exec" {
    command = "kubectl label ns ${each.value} goldilocks.fairwinds.com/enabled=true"
  }
  depends_on = [
    kubernetes_manifest.create_namespace
  ]
}

resource "helm_release" "goldilocks_deploy" {
  name = "goldilocks"

  repository = "https://charts.fairwinds.com/stable"
  chart      = "goldilocks"
  namespace  = "goldilocks"

  set {
    name  = "installVPA"
    value = "true"
  }
  depends_on = [
    kubernetes_manifest.create_namespace
  ]
}
