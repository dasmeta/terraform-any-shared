# Gateway API CRDs installation module
# https://github.com/kubernetes-sigs/gateway-api
# CRDs are installed via kubectl apply --server-side using official manifests from the Gateway API repository
data "http" "gateway_api_crds" {
  url = "https://github.com/kubernetes-sigs/gateway-api/releases/download/${var.crd_version}/standard-install.yaml"
}

# Split multi-document YAML into individual documents
# kubectl_file_documents handles multi-document YAML splitting automatically
data "kubectl_file_documents" "gateway_api_crds" {
  content = data.http.gateway_api_crds.response_body
}

# Apply each CRD document as a separate kubectl_manifest resource
resource "kubectl_manifest" "gateway_api_crds" {
  for_each = data.kubectl_file_documents.gateway_api_crds.manifests

  yaml_body         = each.value
  server_side_apply = true
  wait              = true
}
