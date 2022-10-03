data "kubectl_path_documents" "values" {
  pattern = "${path.module}/helm/values.yaml"
  vars = {
    runnerRegistrationToken = "${var.runnerRegistrationToken}"
    runnerToken             = "${var.runnerToken}"
  }
}

resource "kubectl_manifest" "values_yaml" {
  count     = length(data.kubectl_path_documents.values.documents)
  yaml_body = element(data.kubectl_path_documents.values.documents, count.index)
}

resource "helm_release" "gitlab-runner" {
  name      = var.name
  namespace = var.namespace

  chart            = "./helm/Chart.yaml"
  create_namespace = true
  set {
    name  = "authSecret.create"
    value = true
  }

  set {
    name  = "authSecret.github_token"
    value = var.gitlab_access_token
  }
}
