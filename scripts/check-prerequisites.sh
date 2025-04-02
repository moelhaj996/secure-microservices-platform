#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to check command existence
check_command() {
    if command -v $1 &> /dev/null; then
        echo -e "${GREEN}✓ $1 is installed${NC}"
        $1 version 2>/dev/null || $1 --version 2>/dev/null || echo -e "${YELLOW}Unable to determine version${NC}"
        return 0
    else
        echo -e "${RED}✗ $1 is not installed${NC}"
        return 1
    fi
}

# Function to check Docker status
check_docker_status() {
    if docker info &> /dev/null; then
        echo -e "${GREEN}✓ Docker daemon is running${NC}"
        return 0
    else
        echo -e "${RED}✗ Docker daemon is not running${NC}"
        return 1
    fi
}

# Function to check Kubernetes status
check_kubernetes_status() {
    if kubectl cluster-info &> /dev/null; then
        echo -e "${GREEN}✓ Kubernetes cluster is accessible${NC}"
        kubectl version --short
        return 0
    else
        echo -e "${RED}✗ Kubernetes cluster is not accessible${NC}"
        return 1
    fi
}

echo -e "${YELLOW}Checking prerequisites...${NC}\n"

# Check required tools
REQUIRED_TOOLS=("docker" "kubectl" "helm" "terraform" "istioctl")
MISSING_TOOLS=0

for tool in "${REQUIRED_TOOLS[@]}"; do
    if ! check_command $tool; then
        MISSING_TOOLS=$((MISSING_TOOLS+1))
    fi
    echo ""
done

# Check Docker status
check_docker_status
echo ""

# Check Kubernetes status
check_kubernetes_status
echo ""

# Summary
if [ $MISSING_TOOLS -eq 0 ]; then
    echo -e "${GREEN}All required tools are installed!${NC}"
else
    echo -e "${RED}Missing $MISSING_TOOLS required tool(s)${NC}"
    echo -e "${YELLOW}Please install the missing tools before proceeding.${NC}"
    echo "You can install them using:"
    echo "- Docker: https://docs.docker.com/get-docker/"
    echo "- kubectl: https://kubernetes.io/docs/tasks/tools/"
    echo "- Helm: https://helm.sh/docs/intro/install/"
    echo "- Terraform: https://learn.hashicorp.com/tutorials/terraform/install-cli"
    echo "- istioctl: https://istio.io/latest/docs/setup/getting-started/"
fi 