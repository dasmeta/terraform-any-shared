
output "gateway_api_crds_manifests" {
  value       = try(module.gateway_api_crds[0].manifests, null)
  description = "Map of kubectl_manifest resources for Gateway API CRDs"
}

output "istio_base_helm_metadata" {
  value       = try(helm_release.istio_base[0].metadata, null)
  description = "istio-base Helm release metadata"
}

output "istiod_helm_metadata" {
  value       = try(helm_release.istiod[0].metadata, null)
  description = "istiod Helm release metadata"
}

output "gateway_helm_metadata" {
  value       = try(helm_release.gateway[0].metadata, null)
  description = "Istio gateway Helm release metadata"
}
