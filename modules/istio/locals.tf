locals {
  image_hub = try(var.configs.image.namespace, null) != null ? (
    try(var.configs.image.registry, null) != null ? "${var.configs.image.registry}/${var.configs.image.namespace}" : var.configs.image.namespace
  ) : null

  kiali_image_hub = try(var.configs.kiali.operator.image.namespace, null) != null ? (
    try(var.configs.kiali.operator.image.registry, null) != null ? "${var.configs.kiali.operator.image.registry}/${var.configs.kiali.operator.image.namespace}" : var.configs.kiali.operator.image.namespace
  ) : null

  kiali_operator_image_repo = try(var.configs.kiali.operator.image.repository.operator, null) != null ? (
    local.kiali_image_hub != null ? "${local.kiali_image_hub}/${var.configs.kiali.operator.image.repository.operator}" : var.configs.kiali.operator.image.repository.operator
  ) : null

  kiali_server_image_repo = try(var.configs.kiali.operator.image.repository.server, null) != null ? (
    local.kiali_image_hub != null ? "${local.kiali_image_hub}/${var.configs.kiali.operator.image.repository.server}" : var.configs.kiali.operator.image.repository.server
  ) : null

  image_global_overrides = merge(
    {},
    local.image_hub != null ? { hub = local.image_hub } : {},
    try(var.configs.image.tag, null) != null ? { tag = var.configs.image.tag } : {},
    try(var.configs.image.repository.proxy, null) != null ? { proxy = { image = var.configs.image.repository.proxy } } : {}
  )
  global_image_values = merge(
    length(local.image_global_overrides) > 0 ? { global = local.image_global_overrides } : {},
    try(var.configs.image.repository.istiod, null) != null ? { image = var.configs.image.repository.istiod } : {}
  )
}
