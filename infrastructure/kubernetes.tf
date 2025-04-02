# These resources will be created only after the EKS cluster is ready
# They are moved from main.tf to separate infrastructure deployment into phases

# Create namespaces for different components
resource "kubernetes_namespace" "istio_system" {
  metadata {
    name = "istio-system"
    labels = {
      istio-injection = "disabled"
    }
  }

  depends_on = [module.eks]
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
    labels = {
      istio-injection = "enabled"
    }
  }

  depends_on = [module.eks]
}

resource "kubernetes_namespace" "vault" {
  metadata {
    name = "vault"
    labels = {
      istio-injection = "enabled"
    }
  }

  depends_on = [module.eks]
}

resource "kubernetes_namespace" "applications" {
  metadata {
    name = "applications"
    labels = {
      istio-injection = "enabled"
    }
  }

  depends_on = [module.eks]
}

# Install Istio using Helm
resource "helm_release" "istio_base" {
  name       = "istio-base"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "base"
  namespace  = kubernetes_namespace.istio_system.metadata[0].name
  version    = "1.20.0"

  depends_on = [kubernetes_namespace.istio_system]
}

resource "helm_release" "istiod" {
  name       = "istiod"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "istiod"
  namespace  = kubernetes_namespace.istio_system.metadata[0].name
  version    = "1.20.0"

  values = [
    file("${path.module}/values/istiod-values.yaml")
  ]

  depends_on = [helm_release.istio_base]
}

# Install Prometheus and Grafana for monitoring using kube-prometheus-stack
resource "helm_release" "prometheus_stack" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  version    = "70.4.1"

  set {
    name  = "prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues"
    value = "false"
  }

  set {
    name  = "prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues"
    value = "false"
  }

  depends_on = [kubernetes_namespace.monitoring]
}

# Install HashiCorp Vault
resource "helm_release" "vault" {
  name       = "vault"
  repository = "https://helm.releases.hashicorp.com"
  chart      = "vault"
  namespace  = kubernetes_namespace.vault.metadata[0].name
  version    = "0.27.0"

  values = [
    file("${path.module}/values/vault-values.yaml")
  ]

  depends_on = [kubernetes_namespace.vault]
} 