#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Environment validation
VALID_ENVIRONMENTS=("staging" "production")
ENVIRONMENT=$1

if [[ -z "$ENVIRONMENT" ]]; then
    echo -e "${RED}Error: Environment not specified${NC}"
    echo "Usage: $0 <environment>"
    echo "Valid environments: ${VALID_ENVIRONMENTS[*]}"
    exit 1
fi

if [[ ! " ${VALID_ENVIRONMENTS[@]} " =~ " ${ENVIRONMENT} " ]]; then
    echo -e "${RED}Error: Invalid environment '${ENVIRONMENT}'${NC}"
    echo "Valid environments: ${VALID_ENVIRONMENTS[*]}"
    exit 1
fi

# Configuration
if [ "$ENVIRONMENT" == "production" ]; then
    NAMESPACE="production"
    REPLICAS=3
    RESOURCE_REQUESTS_CPU="500m"
    RESOURCE_REQUESTS_MEMORY="512Mi"
    RESOURCE_LIMITS_CPU="1000m"
    RESOURCE_LIMITS_MEMORY="1024Mi"
else
    NAMESPACE="staging"
    REPLICAS=1
    RESOURCE_REQUESTS_CPU="250m"
    RESOURCE_REQUESTS_MEMORY="256Mi"
    RESOURCE_LIMITS_CPU="500m"
    RESOURCE_LIMITS_MEMORY="512Mi"
fi

echo -e "${GREEN}Starting deployment to ${ENVIRONMENT}...${NC}"

# Verify kubectl access
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}Error: Unable to access Kubernetes cluster${NC}"
    exit 1
fi

# Create or update namespace
kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# Label namespace for Istio injection
kubectl label namespace ${NAMESPACE} istio-injection=enabled --overwrite

# Apply infrastructure changes
echo -e "${YELLOW}Applying infrastructure changes...${NC}"
cd infrastructure
terraform init
terraform workspace select ${ENVIRONMENT} || terraform workspace new ${ENVIRONMENT}
terraform apply -auto-approve \
    -var="environment=${ENVIRONMENT}" \
    -var="replicas=${REPLICAS}" \
    -var="resource_requests_cpu=${RESOURCE_REQUESTS_CPU}" \
    -var="resource_requests_memory=${RESOURCE_REQUESTS_MEMORY}" \
    -var="resource_limits_cpu=${RESOURCE_LIMITS_CPU}" \
    -var="resource_limits_memory=${RESOURCE_LIMITS_MEMORY}"
cd ..

# Deploy Helm charts
echo -e "${YELLOW}Deploying Helm charts...${NC}"
for chart in kubernetes/*/; do
    if [ -f "$chart/Chart.yaml" ]; then
        chart_name=$(basename $chart)
        echo -e "${YELLOW}Deploying ${chart_name}...${NC}"
        helm upgrade --install ${chart_name} ${chart} \
            --namespace ${NAMESPACE} \
            --values ${chart}/values.yaml \
            --values ${chart}/values.${ENVIRONMENT}.yaml \
            --set environment=${ENVIRONMENT} \
            --set replicas=${REPLICAS} \
            --set resources.requests.cpu=${RESOURCE_REQUESTS_CPU} \
            --set resources.requests.memory=${RESOURCE_REQUESTS_MEMORY} \
            --set resources.limits.cpu=${RESOURCE_LIMITS_CPU} \
            --set resources.limits.memory=${RESOURCE_LIMITS_MEMORY}
    fi
done

# Wait for deployments to be ready
echo -e "${YELLOW}Waiting for deployments to be ready...${NC}"
kubectl wait --for=condition=available --timeout=300s deployment --all -n ${NAMESPACE}

# Verify Istio injection
echo -e "${YELLOW}Verifying Istio sidecar injection...${NC}"
PODS_WITHOUT_SIDECAR=$(kubectl get pods -n ${NAMESPACE} -o jsonpath='{.items[?(@.spec.containers[*].name not contains "istio-proxy")].metadata.name}')
if [ ! -z "$PODS_WITHOUT_SIDECAR" ]; then
    echo -e "${RED}Warning: The following pods do not have Istio sidecar injected:${NC}"
    echo "$PODS_WITHOUT_SIDECAR"
fi

# Run security checks
echo -e "${YELLOW}Running security checks...${NC}"
if command -v trivy &> /dev/null; then
    echo "Running Trivy vulnerability scanner..."
    trivy k8s --namespace ${NAMESPACE} cluster
fi

# Verify Vault status
echo -e "${YELLOW}Verifying Vault status...${NC}"
kubectl exec -n vault vault-0 -- vault status || true

# Print deployment summary
echo -e "${GREEN}Deployment to ${ENVIRONMENT} completed successfully!${NC}"
echo -e "${YELLOW}Deployment Summary:${NC}"
echo "Namespace: ${NAMESPACE}"
echo "Replicas: ${REPLICAS}"
echo "Resource Requests CPU: ${RESOURCE_REQUESTS_CPU}"
echo "Resource Requests Memory: ${RESOURCE_REQUESTS_MEMORY}"
echo "Resource Limits CPU: ${RESOURCE_LIMITS_CPU}"
echo "Resource Limits Memory: ${RESOURCE_LIMITS_MEMORY}"

# Print service URLs
echo -e "${YELLOW}Service URLs:${NC}"
kubectl get ingress -n ${NAMESPACE} -o jsonpath='{range .items[*]}{.metadata.name}: https://{.spec.rules[*].host}{"\n"}{end}'

echo -e "${GREEN}Deployment completed successfully!${NC}"
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Verify application health: kubectl get pods -n ${NAMESPACE}"
echo "2. Check logs: kubectl logs -n ${NAMESPACE} <pod-name>"
echo "3. Monitor metrics in Grafana"
echo "4. Review security scan results" 