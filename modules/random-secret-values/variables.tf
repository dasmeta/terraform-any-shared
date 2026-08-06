variable "generated_values" {
  type = map(object({
    length           = number
    special          = optional(bool, true)
    upper            = optional(bool, true)
    lower            = optional(bool, true)
    numeric          = optional(bool, true)
    min_upper        = optional(number, 0)
    min_lower        = optional(number, 0)
    min_numeric      = optional(number, 0)
    min_special      = optional(number, 0)
    override_special = optional(string, null)
  }))
  description = "Named random password policies. Each key becomes one generated sensitive value."

  validation {
    condition = (
      length(var.generated_values) > 0 &&
      alltrue([
        for key, policy in var.generated_values :
        length(trimspace(key)) > 0 &&
        policy.length >= 8 &&
        floor(policy.length) == policy.length &&
        policy.min_upper >= 0 && floor(policy.min_upper) == policy.min_upper &&
        policy.min_lower >= 0 && floor(policy.min_lower) == policy.min_lower &&
        policy.min_numeric >= 0 && floor(policy.min_numeric) == policy.min_numeric &&
        policy.min_special >= 0 && floor(policy.min_special) == policy.min_special &&
        policy.min_upper + policy.min_lower + policy.min_numeric + policy.min_special <= policy.length &&
        (policy.upper || policy.min_upper == 0) &&
        (policy.lower || policy.min_lower == 0) &&
        (policy.numeric || policy.min_numeric == 0) &&
        (policy.special || policy.min_special == 0)
      ])
    )
    error_message = "generated_values must be non-empty; keys must not be blank; lengths must be whole numbers of at least 8; and enabled character minima must be non-negative whole numbers that fit within length."
  }
}

variable "static_values" {
  type        = map(string)
  default     = {}
  description = "Optional static values merged into the sensitive result map, such as a fixed database owner name."

  validation {
    condition     = alltrue([for key in keys(var.static_values) : length(trimspace(key)) > 0])
    error_message = "static_values keys must not be blank."
  }
}

variable "aliases" {
  type        = map(string)
  default     = {}
  description = "Optional destination-to-source key mappings. Each source must be a generated or static key; aliases cannot reference aliases."

  validation {
    condition = alltrue([
      for destination, source in var.aliases :
      length(trimspace(destination)) > 0 && length(trimspace(source)) > 0
    ])
    error_message = "aliases must use non-blank destination and source keys."
  }
}
