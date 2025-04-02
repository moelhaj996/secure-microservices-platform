#!/bin/bash

set -e

# Set colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "🔧 Setting up test environment..."

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ kubectl is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    echo -e "${RED}❌ helm is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}❌ terraform is not installed. Please install it first.${NC}"
    exit 1
fi

# Create a test Kubernetes context if needed
echo "📦 Setting up test Kubernetes context..."
kubectl config use-context docker-desktop || {
    echo -e "${RED}❌ Failed to switch to docker-desktop context${NC}"
    echo "Using current context instead"
}

# Create necessary test namespaces
echo "🔧 Creating test namespaces..."
kubectl create namespace istio-system --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace vault --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace applications --dry-run=client -o yaml | kubectl apply -f -

echo -e "${GREEN}✅ Test environment setup complete!${NC}"
echo "You can now run the integration tests." 