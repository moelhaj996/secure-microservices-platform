package integration

import (
	"context"
	"testing"
	"time"

	v1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/tools/clientcmd"
)

func setupKubernetesClient(t *testing.T) *kubernetes.Clientset {
	config, err := clientcmd.BuildConfigFromFlags("", clientcmd.RecommendedHomeFile)
	if err != nil {
		t.Skipf("Skipping test: %v", err)
		return nil
	}

	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		t.Fatalf("Failed to create kubernetes client: %v", err)
	}

	return clientset
}

func TestKubernetesConnection(t *testing.T) {
	clientset := setupKubernetesClient(t)
	if clientset == nil {
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	// List namespaces
	namespaces, err := clientset.CoreV1().Namespaces().List(ctx, metav1.ListOptions{})
	if err != nil {
		t.Fatalf("Failed to list namespaces: %v", err)
	}

	if len(namespaces.Items) == 0 {
		t.Error("No namespaces found in the cluster")
	}
}

func TestIstioInstallation(t *testing.T) {
	clientset := setupKubernetesClient(t)
	if clientset == nil {
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	// Check if istio-system namespace exists
	ns, err := clientset.CoreV1().Namespaces().Get(ctx, "istio-system", metav1.GetOptions{})
	if err != nil {
		t.Fatalf("Istio system namespace not found: %v", err)
	}

	// Check if istiod deployment exists and is ready
	deployments, err := clientset.AppsV1().Deployments("istio-system").List(ctx, metav1.ListOptions{
		LabelSelector: "app=istiod",
	})
	if err != nil {
		t.Fatalf("Failed to list istiod deployments: %v", err)
	}

	if len(deployments.Items) == 0 {
		t.Fatal("No istiod deployment found")
	}

	if deployments.Items[0].Status.ReadyReplicas == 0 {
		t.Error("Istiod deployment has no ready replicas")
	}
}

func TestMonitoringStack(t *testing.T) {
	clientset := setupKubernetesClient(t)
	if clientset == nil {
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	// Check monitoring namespace
	ns, err := clientset.CoreV1().Namespaces().Get(ctx, "monitoring", metav1.GetOptions{})
	if err != nil {
		t.Fatalf("Monitoring namespace not found: %v", err)
	}

	// Check Prometheus pods
	pods, err := clientset.CoreV1().Pods("monitoring").List(ctx, metav1.ListOptions{
		LabelSelector: "app=prometheus",
	})
	if err != nil {
		t.Fatalf("Failed to list Prometheus pods: %v", err)
	}

	if len(pods.Items) == 0 {
		t.Fatal("No Prometheus pods found")
	}

	// Check Grafana pods
	pods, err = clientset.CoreV1().Pods("monitoring").List(ctx, metav1.ListOptions{
		LabelSelector: "app=grafana",
	})
	if err != nil {
		t.Fatalf("Failed to list Grafana pods: %v", err)
	}

	if len(pods.Items) == 0 {
		t.Fatal("No Grafana pods found")
	}

	// Check pod status
	for _, pod := range pods.Items {
		if pod.Status.Phase != v1.PodRunning {
			t.Errorf("Pod %s is not running (status: %s)", pod.Name, pod.Status.Phase)
		}
	}
} 