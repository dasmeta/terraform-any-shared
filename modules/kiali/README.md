# kiali

Terraform module to install the Kiali operator and manage a `Kiali` custom resource.

The module installs the `kiali-operator` Helm chart by default and creates a Kiali CR in `istio-system`. Kiali is configured through a grouped `configs` object with common Prometheus and Grafana integration fields plus a raw `spec` overlay for advanced Kiali CR settings. The Helm chart repository and operator image parameters are separate top-level variables.

When custom Kiali server image is set via Kiali CR deployment fields (`spec.deployment.image_name` and `spec.deployment.image_version`), the module automatically enables operator chart value `allowAdHocKialiImage=true`. This is handled internally and is not exposed as a user-facing input.

## Usage

```hcl
module "kiali" {
  source = "dasmeta/shared/any//modules/kiali"
  # version = "x.y.z" # Check https://registry.terraform.io/modules/dasmeta/shared/any/latest/submodules/kiali and set the version

  configs = {
    operator = {
      chart_repository = "https://kiali.org/helm-charts"
      image = {
        tag = "latest"
      }
    }
    cr = {
      auth_strategy  = "anonymous"
      view_only_mode = true

      external_services = {
        prometheus = {
          url = "http://prometheus.monitoring:9090/"
        }

        grafana = {
          enabled        = true
          internal_url   = "http://grafana.monitoring:3000/"
          external_url   = "https://grafana.example.com/"
          datasource_uid = "prometheus"
          dashboards = [
            {
              name = "Istio Service Dashboard"
              variables = {
                datasource = "var-datasource"
                namespace  = "var-namespace"
                service    = "var-service"
              }
            },
            {
              name = "Istio Workload Dashboard"
              variables = {
                datasource = "var-datasource"
                namespace  = "var-namespace"
                workload   = "var-workload"
              }
            }
          ]
        }
      }
    }
  }
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.0 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | ~> 1.14 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | ~> 2.0 |
| <a name="provider_kubectl"></a> [kubectl](#provider\_kubectl) | ~> 1.14 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.operator](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubectl_manifest.this](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_chart_repository"></a> [chart\_repository](#input\_chart\_repository) | Kiali Helm chart repository | `string` | `"https://kiali.org/helm-charts"` | no |
| <a name="input_configs"></a> [configs](#input\_configs) | Kiali operator and Kiali custom resource configuration | <pre>object({<br/>    enabled = optional(bool, true) # whether to deploy Kiali observability components<br/>    operator = optional(object({<br/>      enabled          = optional(bool, true)               # whether to install the Kiali operator Helm chart<br/>      name             = optional(string, "kiali-operator") # the Kiali operator Helm release name<br/>      namespace        = optional(string, "kiali-operator") # the namespace where the Kiali operator will be installed<br/>      chart            = optional(string, "kiali-operator") # the Kiali operator chart name<br/>      chart_version    = optional(string, null)             # optional Kiali operator chart version<br/>      create_namespace = optional(bool, true)               # whether Helm should create the operator namespace<br/>      atomic           = optional(bool, false)              # whether Helm should roll back on failure<br/>      wait             = optional(bool, true)               # whether Helm should wait for resources to become ready<br/>      values           = optional(any, {})                  # Kiali operator chart values<br/>      extra_values     = optional(any, {})                  # extra Kiali operator chart values<br/>    }), {})<br/>    cr = optional(object({<br/>      enabled        = optional(bool, true)             # whether to create a Kiali custom resource<br/>      name           = optional(string, "kiali")        # the Kiali custom resource name<br/>      namespace      = optional(string, "istio-system") # the Kiali custom resource namespace<br/>      labels         = optional(map(string), {})        # labels applied to the Kiali custom resource<br/>      annotations    = optional(map(string), {})        # annotations applied to the Kiali custom resource<br/>      auth_strategy  = optional(string, "anonymous")    # Kiali auth strategy<br/>      view_only_mode = optional(bool, false)            # whether Kiali should run in view-only mode<br/>      deployment     = optional(any, {})                # Kiali spec.deployment overrides<br/>      external_services = optional(object({<br/>        prometheus = optional(object({<br/>          url              = optional(string)      # Prometheus internal service URL used by Kiali<br/>          auth             = optional(any)         # Prometheus auth configuration<br/>          custom_headers   = optional(map(string)) # custom headers sent to Prometheus<br/>          health_check_url = optional(string)      # optional Prometheus health check URL<br/>          is_core          = optional(bool)        # whether Prometheus is a core service<br/>          query_scope      = optional(map(string)) # query scope labels such as mesh_id or cluster<br/>          thanos_proxy     = optional(any)         # Thanos proxy configuration<br/>          extra_configs    = optional(any, {})     # extra Prometheus settings merged into spec.external_services.prometheus<br/>        }), {})<br/>        grafana = optional(object({<br/>          enabled          = optional(bool)      # whether Grafana integration is enabled<br/>          internal_url     = optional(string)    # Grafana URL reachable inside the cluster<br/>          external_url     = optional(string)    # Grafana URL opened by users from Kiali<br/>          datasource_uid   = optional(string)    # Grafana datasource UID for Prometheus<br/>          dashboards       = optional(list(any)) # Grafana dashboard definitions used by Kiali links<br/>          auth             = optional(any)       # Grafana auth configuration<br/>          health_check_url = optional(string)    # optional Grafana health check URL<br/>          is_core          = optional(bool)      # whether Grafana is a core service<br/>          extra_configs    = optional(any, {})   # extra Grafana settings merged into spec.external_services.grafana<br/>        }), {})<br/>      }), {})<br/>      spec = optional(any, {}) # extra Kiali CR spec values; overrides generated common-case fields on key conflict<br/>    }), {})<br/>  })</pre> | `{}` | no |
| <a name="input_image"></a> [image](#input\_image) | Kiali operator image parameters | <pre>object({<br/>    repo                     = optional(string) # operator image repository override<br/>    tag                      = optional(string) # operator image tag override<br/>    digest                   = optional(string) # operator image digest override<br/>    allow_ad_hoc_kiali_image = optional(bool)   # whether the operator may use ad hoc Kiali server images<br/>  })</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_manifest"></a> [manifest](#output\_manifest) | Kiali custom resource manifest |
| <a name="output_operator_helm_metadata"></a> [operator\_helm\_metadata](#output\_operator\_helm\_metadata) | Kiali operator Helm release metadata |
<!-- END_TF_DOCS -->
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.0 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | ~> 1.14 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | ~> 2.0 |
| <a name="provider_kubectl"></a> [kubectl](#provider\_kubectl) | ~> 1.14 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.operator](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubectl_manifest.this](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_configs"></a> [configs](#input\_configs) | Kiali operator and Kiali custom resource configuration | <pre>object({<br/>    enabled = optional(bool, true) # whether to deploy Kiali observability components<br/>    operator = optional(object({<br/>      enabled          = optional(bool, true)                              # whether to install the Kiali operator Helm chart<br/>      name             = optional(string, "kiali-operator")                # the Kiali operator Helm release name<br/>      namespace        = optional(string, "kiali-operator")                # the namespace where the Kiali operator will be installed<br/>      chart            = optional(string, "kiali-operator")                # the Kiali operator chart name<br/>      chart_repository = optional(string, "https://kiali.org/helm-charts") # Kiali operator Helm chart repository<br/>      chart_version    = optional(string, "2.25.0")                        # optional Kiali operator chart version<br/>      create_namespace = optional(bool, true)                              # whether Helm should create the operator namespace<br/>      atomic           = optional(bool, false)                             # whether Helm should roll back on failure<br/>      wait             = optional(bool, true)                              # whether Helm should wait for resources to become ready<br/>      image = optional(object({<br/>        # Kiali operator chart exposes image.repo/tag/digest for operator image itself.<br/>        # When Kiali server custom image is configured through Kiali CR deployment fields<br/>        # (`spec.deployment.image_name` / `image_version`), this module auto-enables<br/>        # chart value `allowAdHocKialiImage=true` internally; no explicit field is required.<br/>        repo   = optional(string) # operator image repository override<br/>        tag    = optional(string) # operator image tag override<br/>        digest = optional(string) # operator image digest override<br/>      }), {})<br/>      values       = optional(any, {}) # Kiali operator chart values<br/>      extra_values = optional(any, {}) # extra Kiali operator chart values<br/>    }), {})<br/>    cr = optional(object({<br/>      enabled        = optional(bool, true)             # whether to create a Kiali custom resource<br/>      name           = optional(string, "kiali")        # the Kiali custom resource name<br/>      namespace      = optional(string, "istio-system") # the Kiali custom resource namespace<br/>      labels         = optional(map(string), {})        # labels applied to the Kiali custom resource<br/>      annotations    = optional(map(string), {})        # annotations applied to the Kiali custom resource<br/>      auth_strategy  = optional(string, "anonymous")    # Kiali auth strategy<br/>      view_only_mode = optional(bool, false)            # whether Kiali should run in view-only mode<br/>      deployment     = optional(any, {})                # Kiali spec.deployment overrides<br/>      external_services = optional(object({<br/>        prometheus = optional(object({<br/>          url              = optional(string)      # Prometheus internal service URL used by Kiali<br/>          auth             = optional(any)         # Prometheus auth configuration<br/>          custom_headers   = optional(map(string)) # custom headers sent to Prometheus<br/>          health_check_url = optional(string)      # optional Prometheus health check URL<br/>          is_core          = optional(bool)        # whether Prometheus is a core service<br/>          query_scope      = optional(map(string)) # query scope labels such as mesh_id or cluster<br/>          thanos_proxy     = optional(any)         # Thanos proxy configuration<br/>          extra_configs    = optional(any, {})     # extra Prometheus settings merged into spec.external_services.prometheus<br/>        }), {})<br/>        grafana = optional(object({<br/>          enabled          = optional(bool)      # whether Grafana integration is enabled<br/>          internal_url     = optional(string)    # Grafana URL reachable inside the cluster<br/>          external_url     = optional(string)    # Grafana URL opened by users from Kiali<br/>          datasource_uid   = optional(string)    # Grafana datasource UID for Prometheus<br/>          dashboards       = optional(list(any)) # Grafana dashboard definitions used by Kiali links<br/>          auth             = optional(any)       # Grafana auth configuration<br/>          health_check_url = optional(string)    # optional Grafana health check URL<br/>          is_core          = optional(bool)      # whether Grafana is a core service<br/>          extra_configs    = optional(any, {})   # extra Grafana settings merged into spec.external_services.grafana<br/>        }), {})<br/>      }), {})<br/>      spec = optional(any, {}) # extra Kiali CR spec values; overrides generated common-case fields on key conflict<br/>    }), {})<br/>  })</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_manifest"></a> [manifest](#output\_manifest) | Kiali custom resource manifest |
| <a name="output_operator_helm_metadata"></a> [operator\_helm\_metadata](#output\_operator\_helm\_metadata) | Kiali operator Helm release metadata |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
