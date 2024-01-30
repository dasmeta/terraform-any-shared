module "loki" {

  count = var.loki_storage.type == "digitalocean" ? 1 : 0

  source  = "terraform-module/release/helm"
  version = "2.8.1"

  namespace  = var.namespace
  repository = "https://grafana.github.io/helm-charts"

  app = {
    name    = var.name
    version = var.chart_version
    chart   = "loki-stack"
    deploy  = 1
  }
  values = [
    templatefile("${path.module}/configs/digitalocean-loki-values.yaml",
      {
        access_key        = "${var.loki_storage.access_key}",
        secret_access_key = "${var.loki_storage.secret_access_key}"
        bucketnames       = "${var.loki_storage.bucketname}",
        endpoint          = "${var.loki_storage.endpoint}",
        region            = "${var.loki_storage.region}"
        cache_ttl         = "${var.loki_storage.cache_ttl}"
        period            = "${var.loki_storage.period}"
    })
  ]
}
