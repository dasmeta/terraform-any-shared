resource "random_password" "this" {
  for_each = var.generated_values

  length           = each.value.length
  special          = each.value.special
  upper            = each.value.upper
  lower            = each.value.lower
  numeric          = each.value.numeric
  min_upper        = each.value.min_upper
  min_lower        = each.value.min_lower
  min_numeric      = each.value.min_numeric
  min_special      = each.value.min_special
  override_special = each.value.override_special
}
