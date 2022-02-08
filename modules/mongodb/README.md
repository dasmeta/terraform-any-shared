# This module intended to add MongoDB  in onpremise kubernetes setup and will do the following: 
* Default will created mongodb replicaset if you want change setup standalone please change from variables.tf file
* If created with replicaset pods will created with statesfulset, if change setup type standalone pods will created with deployments


## minimal module setup
```terraform
module "mongodb" {
  source  = "dasmeta/shared/any//modules/mongodb"
  version = "0.2.0"
}
