# basic

Deploys AKHQ with placeholder Kafka bootstrap and Ingress annotations suitable for AWS LBC-style ALB.

Use `terraform.tfvars` (gitignored) for `security.basic_auth_password` in real environments.

Prerequisites:

- Kubernetes cluster
- Kafka bootstrap reachable from the cluster
- Ingress controller matching `ingress.annotations` if Ingress stays enabled
