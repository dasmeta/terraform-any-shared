# Quickstart: Official GitHub ARC Runner Scale Sets

1. Create or reference an existing Kubernetes Secret in the target namespace
   with a `github_token` key.
2. Configure the module with `deployment_mode = "scale_set"` and a generic
   organization or repository GitHub URL.
3. Set a unique `runner_scale_set_name`, `min_runners`, and `max_runners`.
4. For Terraform Cloud Kubernetes environment credentials, set
   `kubectl_config_path = null`.
5. Change workflows to use the configured scale-set name in `runs-on`.
6. Verify the controller, listener, and ephemeral runner pods in the chosen
   namespace. The chart keeps the configured idle baseline and adds runners as
   jobs are assigned, up to the configured maximum.
