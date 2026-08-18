# Module Interface Contract: Official GitHub ARC Runner Scale Sets

## Legacy contract

When `deployment_mode` is omitted or `legacy`, all existing inputs and rendered
legacy behavior remain supported. The historical Helm address moves internally
without replacement through Terraform state migration metadata.

## Official scale-set contract

```hcl
deployment_mode = "scale_set"

scale_set = {
  github_config_url             = "https://github.com/example"
  runner_scale_set_name         = "example-runners"
  min_runners                   = 1
  max_runners                   = 3
  controller_chart_version      = "0.14.2"
  chart_version                 = "0.14.2"
}
```

Exactly one existing module authentication input must be present. The external
Secret is in the same namespace and uses the official chart's `github_token`
key for PAT authentication, or the documented GitHub App keys when managed
outside the module.

## Workflow contract

```yaml
runs-on: example-runners
```

The runner scale-set name replaces generic self-hosted labels in migrated
workflows.
