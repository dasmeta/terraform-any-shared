locals {
  generated_keys = keys(var.generated_values)
  static_keys    = keys(var.static_values)
  alias_keys     = keys(var.aliases)

  all_keys = concat(local.generated_keys, local.static_keys, local.alias_keys)

  base_values = merge(
    var.static_values,
    { for key, password in random_password.this : key => password.result },
  )

  alias_values = {
    for destination, source in var.aliases :
    destination => lookup(local.base_values, source, "")
  }

  values = merge(local.base_values, local.alias_values)

  unique_keys      = length(distinct(local.all_keys)) == length(local.all_keys)
  valid_aliases    = alltrue([for source in values(var.aliases) : contains(keys(local.base_values), source)])
  result_key_names = sort(keys(local.values))
}
