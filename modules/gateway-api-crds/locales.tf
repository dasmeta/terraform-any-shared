locals {
  # we need this mapping as tf fails to get the count of items dynamically from the file content
  version_to_crds_map = {
    "v1.4.1" = [
      "/apis/apiextensions.k8s.io/v1/customresourcedefinitions/backendtlspolicies.gateway.networking.k8s.io",
      "/apis/apiextensions.k8s.io/v1/customresourcedefinitions/gatewayclasses.gateway.networking.k8s.io",
      "/apis/apiextensions.k8s.io/v1/customresourcedefinitions/gateways.gateway.networking.k8s.io",
      "/apis/apiextensions.k8s.io/v1/customresourcedefinitions/grpcroutes.gateway.networking.k8s.io",
      "/apis/apiextensions.k8s.io/v1/customresourcedefinitions/httproutes.gateway.networking.k8s.io",
      "/apis/apiextensions.k8s.io/v1/customresourcedefinitions/referencegrants.gateway.networking.k8s.io"
    ]
  }
}
