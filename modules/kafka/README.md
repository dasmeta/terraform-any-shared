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
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

No requirements.

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_kafka"></a> [kafka](#module\_kafka) | terraform-module/release/helm | 2.7.0 |
| <a name="module_kafka_ui"></a> [kafka\_ui](#module\_kafka\_ui) | terraform-module/release/helm | 2.7.0 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Bitnami Kafka chart version | `string` | `"21.4.6"` | no |
| <a name="input_create_namespace"></a> [create\_namespace](#input\_create\_namespace) | Create Namespace | `bool` | `true` | no |
| <a name="input_deploy"></a> [deploy](#input\_deploy) | Deploy | `number` | `1` | no |
| <a name="input_enable_kafka_ui"></a> [enable\_kafka\_ui](#input\_enable\_kafka\_ui) | n/a | `bool` | `true` | no |
| <a name="input_force_update"></a> [force\_update](#input\_force\_update) | Force Update | `bool` | `true` | no |
| <a name="input_helm_set"></a> [helm\_set](#input\_helm\_set) | Helm Set value | `any` | `[]` | no |
| <a name="input_kafka_cluster_0_bootstrapservers"></a> [kafka\_cluster\_0\_bootstrapservers](#input\_kafka\_cluster\_0\_bootstrapservers) | n/a | `string` | `"kafka.kafka.svc.cluster.local:9092"` | no |
| <a name="input_kafka_cluster_0_name"></a> [kafka\_cluster\_0\_name](#input\_kafka\_cluster\_0\_name) | n/a | `string` | `"local"` | no |
| <a name="input_kafka_cluster_0_zookeeper"></a> [kafka\_cluster\_0\_zookeeper](#input\_kafka\_cluster\_0\_zookeeper) | n/a | `string` | `"kafka-zookeeper.kafka.svc.cluster.local:2181"` | no |
| <a name="input_kafka_ui_chart_version"></a> [kafka\_ui\_chart\_version](#input\_kafka\_ui\_chart\_version) | n/a | `string` | `"0.6.2"` | no |
| <a name="input_name"></a> [name](#input\_name) | App Name | `string` | `"kafka"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace | `string` | `"kafka"` | no |
| <a name="input_recreate_pods"></a> [recreate\_pods](#input\_recreate\_pods) | Recreate pods | `bool` | `false` | no |
| <a name="input_resources_limits"></a> [resources\_limits](#input\_resources\_limits) | The resources limits for MongoDB containers | `any` | `{}` | no |
| <a name="input_resources_requests"></a> [resources\_requests](#input\_resources\_requests) | The resources resources for MongoDB containers | `any` | `{}` | no |
| <a name="input_wait"></a> [wait](#input\_wait) | Wait | `bool` | `false` | no |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
