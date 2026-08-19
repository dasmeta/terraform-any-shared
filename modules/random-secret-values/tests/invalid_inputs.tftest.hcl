run "generates_sensitive_composed_values" {
  command = apply

  variables {
    generated_values = {
      application_key = {
        length = 48
      }
      database_password = {
        length = 24
      }
    }
    static_values = {
      username = "application_owner"
    }
    aliases = {
      password = "database_password"
    }
  }

  assert {
    condition = (
      toset(output.keys) == toset(["application_key", "database_password", "password", "username"]) &&
      length(nonsensitive(output.values).application_key) == 48 &&
      length(nonsensitive(output.values).database_password) == 24 &&
      nonsensitive(output.values).password == nonsensitive(output.values).database_password &&
      nonsensitive(output.values).username == "application_owner"
    )
    error_message = "The module must generate configured values and preserve static and alias fields in one sensitive payload."
  }
}

run "rejects_short_generated_value" {
  command = plan

  variables {
    generated_values = {
      database_password = {
        length = 7
      }
    }
  }

  expect_failures = [var.generated_values]
}

run "rejects_character_minimum_when_disabled" {
  command = plan

  variables {
    generated_values = {
      database_password = {
        length      = 24
        special     = false
        min_special = 1
      }
    }
  }

  expect_failures = [var.generated_values]
}

run "rejects_key_collisions" {
  command = plan

  variables {
    generated_values = {
      password = {
        length = 24
      }
    }
    static_values = {
      password = "owner"
    }
  }

  expect_failures = [output.values]
}

run "rejects_aliases_to_aliases" {
  command = plan

  variables {
    generated_values = {
      password = {
        length = 24
      }
    }
    aliases = {
      database_password    = "password"
      application_password = "database_password"
    }
  }

  expect_failures = [output.values]
}
