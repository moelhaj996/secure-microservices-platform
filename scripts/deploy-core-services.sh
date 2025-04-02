#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Starting deployment of core services...${NC}"

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}kubectl is not installed. Please run setup.sh first.${NC}"
    exit 1
fi

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo -e "${RED}Docker is not running. Please start Docker Desktop.${NC}"
    exit 1
fi

# Build API service
echo -e "${YELLOW}Building API service...${NC}"
cd ../services/api-service
docker build -t api-service:latest .

# Apply Kubernetes configurations
echo -e "${YELLOW}Applying Kubernetes configurations...${NC}"
cd ../../kubernetes

# Wait for namespaces to be ready
kubectl wait --for=condition=Ready namespace/istio-system --timeout=60s
kubectl wait --for=condition=Ready namespace/vault --timeout=60s
kubectl wait --for=condition=Ready namespace/monitoring --timeout=60s
kubectl wait --for=condition=Ready namespace/services --timeout=60s

# Deploy API service
echo -e "${YELLOW}Deploying API service...${NC}"
kubectl apply -f api-service.yaml

# Wait for deployments
echo -e "${YELLOW}Waiting for deployments to be ready...${NC}"
kubectl wait --for=condition=Available deployment/api-service -n services --timeout=120s

# Initialize Vault
echo -e "${YELLOW}Initializing Vault...${NC}"
kubectl exec -n vault vault-0 -- vault operator init > ../infrastructure/vault-keys.txt

# Unseal Vault (this is for demonstration - in production, use a proper key management solution)
UNSEAL_KEY=$(grep "Unseal Key 1" ../infrastructure/vault-keys.txt | awk '{print $4}')
ROOT_TOKEN=$(grep "Initial Root Token" ../infrastructure/vault-keys.txt | awk '{print $4}')

kubectl exec -n vault vault-0 -- vault operator unseal $UNSEAL_KEY

# Configure Vault
echo -e "${YELLOW}Configuring Vault...${NC}"
kubectl exec -n vault vault-0 -- vault login $ROOT_TOKEN

# Enable Kubernetes authentication
kubectl exec -n vault vault-0 -- vault auth enable kubernetes

# Configure Kubernetes authentication
VAULT_SA_NAME=$(kubectl get sa vault -n vault -o jsonpath="{.secrets[*]['name']}")
SA_JWT_TOKEN=$(kubectl get secret $VAULT_SA_NAME -n vault -o jsonpath="{.data.token}" | base64 --decode)
SA_CA_CRT=$(kubectl get secret $VAULT_SA_NAME -n vault -o jsonpath="{.data['ca\.crt']}" | base64 --decode)
K8S_HOST=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')

kubectl exec -n vault vault-0 -- vault write auth/kubernetes/config \
    token_reviewer_jwt="$SA_JWT_TOKEN" \
    kubernetes_host="$K8S_HOST" \
    kubernetes_ca_cert="$SA_CA_CRT"

# Create a policy for the API service
kubectl exec -n vault vault-0 -- vault policy write api-service - <<EOF
path "secret/data/api-service/*" {
  capabilities = ["read"]
}
EOF

# Create a role for the API service
kubectl exec -n vault vault-0 -- vault write auth/kubernetes/role/api-service \
    bound_service_account_names=api-service \
    bound_service_account_namespaces=services \
    policies=api-service \
    ttl=1h

echo -e "${GREEN}Core services deployment completed!${NC}"
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Access the API service at http://localhost:8080"
echo "2. Monitor the services using Grafana at http://localhost:3000"
echo "3. Check Vault status at http://localhost:8200" 