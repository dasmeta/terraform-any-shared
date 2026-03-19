# Configure the Helm provider to use your Kubernetes cluster.
# For example, set KUBECONFIG or use an EKS-authenticated provider in the root module.
#
# export KUBECONFIG=/path/to/your/k8s.kubeconfig
# export KUBE_CONFIG_PATH=$KUBECONFIG
provider "helm" {}
