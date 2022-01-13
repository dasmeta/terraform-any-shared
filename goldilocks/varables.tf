variable "namespaces" {
    type = set(string)
    default = [ "default" ]
    description = "Goldilocks labels on your namespaces"
}

variable "create_metric_server" {
    type = bool
    default = true
    description = "Create metric server"
}

variable "create_vpa_server" {
    type = bool
    default = true
    description = "VPA configure in the cluster"
}
