# Example 1  
```
module "kafka" {
    source = "dasmeta/shared/any//modules/kafka
}
```

# Example 2
```
module "kafka" {
    source = "dasmeta/shared/any//modules/kafka
    name   = "kafka2"
    namespace = "kafka2"
    version   = "15.3.4"
    create_namespace = true
    force_update     = true
    recreate_pods    = false
    wait   = false
    deploy = 1
}
```