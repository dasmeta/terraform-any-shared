## to run the example set helm provider env variables to connect to existing k8s setup by running the following commands(replace `/path/to/your/k8s.kubeconfig` with your k8s cluster kubeconfig path)
# `export KUBECONFIG=/path/to/your/k8s.kubeconfig`
# `export KUBE_CONFIG_PATH=$KUBECONFIG`
provider "helm" {}
