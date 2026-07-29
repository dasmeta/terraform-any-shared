# Quickstart: Shared Kubernetes Namespace Module

1. Configure a Kubernetes provider in the consuming Terraform root.
2. Reference `modules/namespace` with a neutral namespace name and optional
   labels/annotations.
3. Use `namespace_name` in dependent component modules.
4. Run `terraform init -backend=false` and `terraform validate` in the basic
   test fixture before publishing a release.

The module does not configure provider credentials, cluster connectivity,
network policies, service accounts, secrets, or workloads.
