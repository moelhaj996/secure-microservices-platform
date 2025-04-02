package integration

import (
	"context"
	"testing"
	"time"

	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/tools/clientcmd"
)

func TestKubernetesConnection(t *testing.T) {
	// Load kubernetes config
	config, err := clientcmd.BuildConfigFromFlags("", clientcmd.RecommendedHomeFile)
	if err != nil {
		t.Skipf("Skipping test: %v", err)
	}

	// Create kubernetes client
	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		t.Fatalf("Failed to create kubernetes client: %v", err)
	}

	// Test namespace creation
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// List namespaces
	_, err = clientset.CoreV1().Namespaces().List(ctx, metav1.ListOptions{})
	if err != nil {
		t.Fatalf("Failed to list namespaces: %v", err)
	}
}

func TestIstioInstallation(t *testing.T) {
	// Load kubernetes config
	config, err := clientcmd.BuildConfigFromFlags("", clientcmd.RecommendedHomeFile)
	if err != nil {
		t.Skipf("Skipping test: %v", err)
	}

	// Create kubernetes client
	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		t.Fatalf("Failed to create kubernetes client: %v", err)
	}

	// Check if istio-system namespace exists
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	_, err = clientset.CoreV1().Namespaces().Get(ctx, "istio-system", metav1.GetOptions{})
	if err != nil {
		t.Fatalf("Istio system namespace not found: %v", err)
	}
}

func TestMonitoringStack(t *testing.T) {
	// Load kubernetes config
	config, err := clientcmd.BuildConfigFromFlags("", clientcmd.RecommendedHomeFile)
	if err != nil {
		t.Skipf("Skipping test: %v", err)
	}

	// Create kubernetes client
	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		t.Fatalf("Failed to create kubernetes client: %v", err)
	}

	// Check if monitoring namespace exists
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	_, err = clientset.CoreV1().Namespaces().Get(ctx, "monitoring", metav1.GetOptions{})
	if err != nil {
		t.Fatalf("Monitoring namespace not found: %v", err)
	}
} 