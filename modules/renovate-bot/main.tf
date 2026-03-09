resource "helm_release" "this" {
  name             = var.name
  repository       = "https://docs.renovatebot.com/helm-charts"
  chart            = "renovate"
  namespace        = var.namespace
  version          = var.chart_version
  create_namespace = var.create_namespace
  atomic           = var.atomic
  wait             = var.wait

  values = [
    jsonencode({
      renovate = {
        config = jsonencode(merge(var.renovate_configs, var.renovate_extra_configs))
      }
      cronjob = {
        schedule = var.renovate_configs.schedule
      }
      env = {
        GITHUB_COM_TOKEN = var.renovate_configs.github_token
      }
    }),
    jsonencode(var.helm_extra_configs),
  ]
}
