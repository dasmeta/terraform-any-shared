output "release_name" {
  value = module.argocd.release_name
}

output "release_namespace" {
  value = module.argocd.release_namespace
}

output "ingress_hostnames" {
  value = module.argocd.ingress_hostnames
}

output "admin_password_secret_name" {
  value = module.argocd.admin_password_secret_name
}

check "ingress_hostname_matches" {
  assert {
    condition     = length(module.argocd.ingress_hostnames) == 1 && module.argocd.ingress_hostnames[0] == "argocd.example.com"
    error_message = "Expected ingress_hostnames to contain argocd.example.com"
  }
}
