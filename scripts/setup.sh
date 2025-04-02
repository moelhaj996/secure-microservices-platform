#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if running with sudo
if [ "$EUID" -ne 0 ]; then 
    echo -e "${YELLOW}Please run as root or with sudo${NC}"
    exit 1
fi

echo -e "${GREEN}Starting setup of Secure Microservices Platform...${NC}"

# Check for required tools
check_tool() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED}$1 could not be found${NC}"
        return 1
    else
        echo -e "${GREEN}✓ $1 is installed${NC}"
        return 0
    fi
}

# Install tools if missing
install_tools() {
    # Check package manager
    if command -v apt-get &> /dev/null; then
        PKG_MANAGER="apt-get"
        PKG_UPDATE="apt-get update"
    elif command -v yum &> /dev/null; then
        PKG_MANAGER="yum"
        PKG_UPDATE="yum update"
    else
        echo -e "${RED}No supported package manager found${NC}"
        exit 1
    fi

    # Update package lists
    echo "Updating package lists..."
    $PKG_UPDATE

    # Install Docker if not present
    if ! check_tool docker; then
        echo "Installing Docker..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh
        systemctl enable docker
        systemctl start docker
    fi

    # Install kubectl if not present
    if ! check_tool kubectl; then
        echo "Installing kubectl..."
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        chmod +x kubectl
        mv kubectl /usr/local/bin/
    fi

    # Install Helm if not present
    if ! check_tool helm; then
        echo "Installing Helm..."
        curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    fi

    # Install Terraform if not present
    if ! check_tool terraform; then
        echo "Installing Terraform..."
        curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
        apt-get update && apt-get install terraform
    fi

    # Install istioctl if not present
    if ! check_tool istioctl; then
        echo "Installing istioctl..."
        curl -L https://istio.io/downloadIstio | sh -
        mv istio-*/bin/istioctl /usr/local/bin/
        rm -rf istio-*
    fi

    # Install Vault if not present
    if ! check_tool vault; then
        echo "Installing Vault..."
        curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
        apt-get update && apt-get install vault
    fi
}

# Verify Docker is running
verify_docker() {
    if ! docker info &> /dev/null; then
        echo -e "${RED}Docker is not running${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ Docker is running${NC}"
}

# Setup Kubernetes context
setup_kubernetes() {
    if ! kubectl cluster-info &> /dev/null; then
        echo -e "${RED}Kubernetes cluster is not accessible${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ Kubernetes cluster is accessible${NC}"
}

# Main setup process
echo "Checking and installing required tools..."
install_tools

echo "Verifying Docker installation..."
verify_docker

echo "Setting up Kubernetes context..."
setup_kubernetes

echo "Adding Helm repositories..."
helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update

echo -e "${GREEN}Setup completed successfully!${NC}"
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Review and customize the values files in infrastructure/values/"
echo "2. Run 'terraform init' and 'terraform apply' in the infrastructure directory"
echo "3. Configure Vault for secret management"
echo "4. Deploy your microservices" 