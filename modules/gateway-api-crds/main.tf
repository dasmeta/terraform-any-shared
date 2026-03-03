# Gateway API CRDs installation module
# https://github.com/kubernetes-sigs/gateway-api
# CRDs are installed via kubectl apply --server-side using official manifests from the Gateway API repository

# Split multi-document YAML into individual documents
# kubectl_file_documents handles multi-document YAML splitting automatically
data "kubectl_file_documents" "gateway_api_crds" {
  content = file("${path.module}/files/${var.crd_version}-standard-install.yaml") # the file pulled from url "https://github.com/kubernetes-sigs/gateway-api/releases/download/${var.crd_version}/standard-install.yaml"
}

# Apply each CRD document as a separate kubectl_manifest resource
resource "kubectl_manifest" "gateway_api_crds" {
  for_each = toset(local.version_to_crds_map[var.crd_version])

  yaml_body         = data.kubectl_file_documents.gateway_api_crds.manifests[each.key]
  server_side_apply = true
  wait              = true
}
