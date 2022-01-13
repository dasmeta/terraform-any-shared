# todo
- Goldilocks is a Kubernetes controller that provides a dashboard that gives recommendations on how to set your resource requests.

## Usage

# Case 1

The module create Goldilocks installation prerequisites. The module default create the prerequisites.

° vertical-pod-autoscaler configure in the cluster
° metrics-server 

```
module "goldilocks" {
  source     = "dasmeta/terraform-any-modules/goldilocks"

  # You add namespaces for watch recommendations in dashboard.
  namespaces = [ "kube-system" , "goldilocks" ]
}
```

# Case 2

You can disable the prerequisites for the Goldilocks installation if you have already.

```
module "goldilocks" {
  source     = "dasmeta/terraform-any-modules/goldilocks"
  
  # You add namespaces for watch recommendations in dashboard.
  namespaces = [ "kube-system" , "goldilocks" ]

  create_vpa_server    = false
  create_metric_server = false
}
```

