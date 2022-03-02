data "kubectl_path_documents" "docs" {
  pattern = "${path.module}/runner.yaml"
  vars = {
    repository  = "${var.repo_name}"
    runner_name = "${var.runner_name}"
  }
}

resource "kubectl_manifest" "pv_mongo_main" {
  count     = length(data.kubectl_path_documents.docs.documents)
  yaml_body = element(data.kubectl_path_documents.docs.documents, count.index)
}

resource "helm_release" "test" {

  namespace        = "actions-runner-system"
  repository       = "https://actions-runner-controller.github.io/actions-runner-controller"
  chart            = "actions-runner-controller"
  name             = "actions-runner-controller"
  create_namespace = true

  set {
    name  = "authSecret.create"
    value = true
  }
  set {
    name  = "authSecret.github_token"
    value = var.personal_access_token
  }

}
