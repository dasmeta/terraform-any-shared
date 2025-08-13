module "this" {
  source = "../"

  create_namespace = true
  chart_version    = "0.1.0"
  webhookendpoint  = "<WEBHOOK_ENDPOINT>"
  namespace        = "kubernetes-event-exporter"
}
