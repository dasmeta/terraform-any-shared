
output "gateway_api_crds_helm_metadata" {
  value       = try(helm_release.gateway_api_crds[0].metadata, null)
  description = "Gateway API CRDs Helm release metadata"
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
