output "manifests" {
  description = "Map of kubectl_manifest resources for Gateway API CRDs"
  value       = kubectl_manifest.gateway_api_crds
}
