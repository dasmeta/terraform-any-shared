# This module intended to add MongoDB  in onpremise kubernetes setup and will do the following: 
* Default will created mongodb replicaset if you want change setup standalone please change from variables.tf file
* If created with replicaset pods will created with statesfulset, if change setup type standalone pods will created with deployments


## Example 1

```
module "mongodb" {
  source  = "dasmeta/shared/any//modules/mongodb"
  version = "0.2.1"
}
```

## Example 2

```
module "mongodb" {
  source  = "dasmeta/shared/any//modules/mongodb"
  version = "0.2.1"

  root_password  = ""
  replicaset_key = ""
  resources_requests = {
    cpu    = "250m"
    memory = "64Mi"
  }
  resources_limits = {
    cpu    = "500m"
    memory = "128Mi"
  }
}
```