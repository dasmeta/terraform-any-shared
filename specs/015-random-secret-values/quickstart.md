# Quickstart

1. Configure two named random values, a static username, and a password alias.
2. Pass the module's sensitive `values` output to the existing AWS Secret
   module's `value` input.
3. Do not write the generated result to YAML, logs, or a non-sensitive output.
4. For an ExternalSecret consumer, map the resulting AWS Secret properties into
   the required Kubernetes Secret keys.
