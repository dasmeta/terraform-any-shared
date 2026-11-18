# Plan-only tests for the Istio chart defaults and override precedence.
# Providers are mocked, so no cluster connection is required.
mock_provider "helm" {}
mock_provider "kubectl" {}

run "uses_istio_1_32_chart_defaults" {
  command = plan

  variables {
    configs = {
      gateway = {
        crds             = { enabled = false } # CRD manifests cannot be read through a mocked provider
        ingress_gateways = [{}]
      }
    }
  }

  assert {
    condition = alltrue([
      helm_release.istio_base[0].repository == "https://blob.istio.io/istio-release/charts",
      helm_release.istiod[0].repository == "https://blob.istio.io/istio-release/charts",
      helm_release.gateway["istio-ingressgateway"].repository == "https://blob.istio.io/istio-release/charts",
    ])
    error_message = "Istio base, istiod and gateway releases must default to the official Istio chart repository."
  }

  assert {
    condition = alltrue([
      helm_release.istio_base[0].version == "1.32.0",
      helm_release.istiod[0].version == "1.32.0",
      helm_release.gateway["istio-ingressgateway"].version == "1.32.0",
    ])
    error_message = "Istio base, istiod and gateway releases must default to chart version 1.32.0."
  }

  assert {
    condition     = yamldecode(helm_release.istiod[0].values[0]) == {}
    error_message = "Istio images must inherit the chart defaults when no image override is set."
  }
}

run "component_overrides_take_precedence" {
  command = plan

  variables {
    configs = {
      chart = {
        repository = "https://charts.example.com/global"
        version    = "1.31.4"
      }
      image = {
        tag = "1.31.4"
      }
      base = {
        repository = "https://charts.example.com/base"
        version    = "1.31.3"
      }
      istiod = {
        version = "1.31.2"
      }
      gateway = {
        crds = { enabled = false }
        ingress_gateways = [{
          repository = "https://charts.example.com/gateway"
          version    = "1.31.1"
        }]
      }
    }
  }

  assert {
    condition = alltrue([
      helm_release.istio_base[0].repository == "https://charts.example.com/base",
      helm_release.istio_base[0].version == "1.31.3",
      helm_release.istiod[0].repository == "https://charts.example.com/global",
      helm_release.istiod[0].version == "1.31.2",
      helm_release.gateway["istio-ingressgateway"].repository == "https://charts.example.com/gateway",
      helm_release.gateway["istio-ingressgateway"].version == "1.31.1",
    ])
    error_message = "Per-component repository/version must override configs.chart, which must override the module defaults."
  }

  assert {
    condition     = yamldecode(helm_release.istiod[0].values[0]).global.tag == "1.31.4"
    error_message = "configs.image.tag must be passed to istiod as global.tag."
  }
}

run "direct_tgz_charts_skip_repository" {
  command = plan

  variables {
    configs = {
      base = {
        chart = "https://charts.example.com/base-1.31.4.tgz"
      }
      istiod = {
        chart = "https://charts.example.com/istiod-1.31.4.tgz"
      }
      gateway = {
        crds = { enabled = false }
      }
    }
  }

  assert {
    condition = alltrue([
      helm_release.istio_base[0].chart == "https://charts.example.com/base-1.31.4.tgz",
      helm_release.istio_base[0].repository == null,
      helm_release.istiod[0].chart == "https://charts.example.com/istiod-1.31.4.tgz",
      helm_release.istiod[0].repository == null,
    ])
    # version is computed by the helm provider when unset, so it is unknown at plan time
    error_message = "Direct .tgz chart URLs must be used as-is, without the default chart repository."
  }
}
