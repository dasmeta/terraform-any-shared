# Data Model

## Generated value policy

- `key`: destination key in the sensitive map.
- `length`: desired password length.
- `special`, `upper`, `lower`, `numeric`, `min_*`, `override_special`: bounded
  Random provider policy controls.

## Static value

- `key`: destination key in the sensitive map.
- `value`: caller-supplied non-generated metadata.

## Alias

- `key`: additional destination key.
- `source_key`: a generated or static key that the alias must copy.

## Result

- `values`: sensitive map merging generated values, static values, and aliases.
- `keys`: non-sensitive list of result keys for safe diagnostics.
