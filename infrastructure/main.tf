terraform {
  required_version = ">= 1.0.0"
  
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.20.0"
    }
  }

  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

# Create namespaces for different components
resource "kubernetes_namespace" "istio_system" {
  metadata {
    name = "istio-system"
    labels = {
      istio-injection = "disabled"
    }
  }
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
    labels = {
      istio-injection = "enabled"
    }
  }
}

resource "kubernetes_namespace" "vault" {
  metadata {
    name = "vault"
    labels = {
      istio-injection = "enabled"
    }
  }
}

resource "kubernetes_namespace" "applications" {
  metadata {
    name = "applications"
    labels = {
      istio-injection = "enabled"
    }
  }
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

# Install Prometheus and Grafana for monitoring
resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  version    = "25.8.0"

  values = [
    file("${path.module}/values/prometheus-values.yaml")
  ]

  depends_on = [kubernetes_namespace.monitoring]
}

resource "helm_release" "grafana" {
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  version    = "7.0.11"

  values = [
    file("${path.module}/values/grafana-values.yaml")
  ]

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