# Setup github actions runner in k8s, 
# By default, actions-runner-controller uses cert-manager for certificate management of Admission Webhook
# You can install cert manager 'kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.7.1/cert-manager.yaml'


# Example 1 

```
module "action-runner" {
  source                = "/Users/juliaaghamyan/Desktop/dasmeta/terraform-any-modules/modules/github-actions-runner"
  personal_access_token = "ghp_ZhJoqzL******M6FCk"
  kubectl_config_path   = "~/.kube/config"
  repo_name             = "tutor-platform/action-runner"
  runner_name           = "runner"
}
```