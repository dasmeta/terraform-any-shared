
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

output "gateway_api_resources_helm_metadata" {
  value       = try(var.configs.gateway.api_resources.enabled, true) ? helm_release.gateway_api_resources[0].metadata : null
  description = "Gateway API resources Helm release metadata"
}

output "kiali_operator_helm_metadata" {
  value       = try(module.kiali[0].operator_helm_metadata, null)
  description = "Kiali operator Helm release metadata"
}

output "kiali_manifest" {
  value       = try(module.kiali[0].manifest, null)
  description = "Kiali custom resource manifest"
}
