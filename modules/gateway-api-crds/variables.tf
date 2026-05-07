variable "configs" {
  type = object({
    version = optional(string, "v1.5.1")
    crdsList = optional(list(string), [
      "/apis/apiextensions.k8s.io/v1/customresourcedefinitions/backendtlspolicies.gateway.networking.k8s.io",
      "/apis/apiextensions.k8s.io/v1/customresourcedefinitions/gatewayclasses.gateway.networking.k8s.io",
      "/apis/apiextensions.k8s.io/v1/customresourcedefinitions/gateways.gateway.networking.k8s.io",
      "/apis/apiextensions.k8s.io/v1/customresourcedefinitions/grpcroutes.gateway.networking.k8s.io",
      "/apis/apiextensions.k8s.io/v1/customresourcedefinitions/httproutes.gateway.networking.k8s.io",
      "/apis/apiextensions.k8s.io/v1/customresourcedefinitions/listenersets.gateway.networking.k8s.io",
      "/apis/apiextensions.k8s.io/v1/customresourcedefinitions/referencegrants.gateway.networking.k8s.io",
      "/apis/apiextensions.k8s.io/v1/customresourcedefinitions/tlsroutes.gateway.networking.k8s.io",
      "/apis/admissionregistration.k8s.io/v1/validatingadmissionpolicys/safe-upgrades.gateway.networking.k8s.io",
      "/apis/admissionregistration.k8s.io/v1/validatingadmissionpolicybindings/safe-upgrades.gateway.networking.k8s.io",
    ])
  })
  description = "The version of the Gateway API CRDs and the list of CRDs to install. NOTE: This config supposed to be changed when we want to upgrade the Gateway API CRDs version."
  default     = {}
}
