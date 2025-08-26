# todo
- Goldilocks is a Kubernetes controller that provides a dashboard that gives recommendations on how to set your resource requests.

## Usage

# Case 1

The module create Goldilocks installation prerequisites. The module default create the prerequisites.

° vertical-pod-autoscaler configure in the cluster
° metrics-server

```
module "goldilocks" {
  source     = "dasmeta/shared/any//modules/goldilocks"

  # You add namespaces for watch recommendations in dashboard.
  namespaces = [ "kube-system" , "goldilocks" ]
}
```

# Case 2

You can disable the prerequisites for the Goldilocks installation if you have already.

```
module "goldilocks" {
  source     = "dasmeta/shared/any//goldilocks"

  # You add namespaces for watch recommendations in dashboard.
  namespaces = [ "kube-system" , "goldilocks" ]

  create_vpa_server    = false
  create_metric_server = false
}

```

```
# Port-forward for access the dashboard
kubectl -n goldilocks port-forward svc/goldilocks-dashboard 8080:80

# Dashborad url
http://localhost:8080/
```
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | n/a |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | n/a |
| <a name="provider_null"></a> [null](#provider\_null) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.goldilocks_deploy](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.metric_server](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.vpa](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_manifest.create_namespace](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [null_resource.vpa_configure](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_create_metric_server"></a> [create\_metric\_server](#input\_create\_metric\_server) | Create metric server | `bool` | `true` | no |
| <a name="input_create_vpa_server"></a> [create\_vpa\_server](#input\_create\_vpa\_server) | VPA configure in the cluster | `bool` | `true` | no |
| <a name="input_namespaces"></a> [namespaces](#input\_namespaces) | Goldilocks labels on your namespaces | `set(string)` | <pre>[<br/>  "default"<br/>]</pre> | no |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
