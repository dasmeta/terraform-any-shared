# Gateway API CRDs installation terraform module
# official repository of the Gateway API: https://github.com/kubernetes-sigs/gateway-api
# there is no helm chart so based the docs the CRDs are installed via kubectl apply --server-side using official manifests from the Gateway API repository, and here we just wrap it in a terraform module to make it easier to use in other terraform projects

# Split multi-document YAML into individual documents
# kubectl_file_documents handles multi-document YAML splitting automatically
data "kubectl_file_documents" "gateway_api_crds" {
  content = file("${path.module}/files/${var.configs.version}-standard-install.yaml") # file pulled from https://github.com/kubernetes-sigs/gateway-api/releases/download/${var.configs.version}/standard-install.yaml
}

# Apply each CRD document as a separate kubectl_manifest resource
resource "kubectl_manifest" "gateway_api_crds" {
  for_each = toset(var.configs.crdsList)

  yaml_body         = data.kubectl_file_documents.gateway_api_crds.manifests[each.key]
  server_side_apply = true
  wait              = true
}
