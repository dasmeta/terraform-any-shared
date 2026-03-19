output "manifests" {
  description = "Map of kubectl_manifest resources for Gateway API CRDs"
  value       = kubectl_manifest.gateway_api_crds
}
output "crds_keys" {
  description = "Map of dependencies for Gateway API CRDs, can be used to identify which CRDs are included in the manifest"
  value       = keys(data.kubectl_file_documents.gateway_api_crds.manifests)
}
