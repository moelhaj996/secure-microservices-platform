#!/bin/bash

# Reset any previous AWS region settings
unset AWS_REGION
unset AWS_DEFAULT_REGION

# Set the correct region explicitly
export AWS_REGION=us-west-2
export AWS_DEFAULT_REGION=us-west-2

# Update kubeconfig with explicit region parameter
aws eks update-kubeconfig --name secure-microservices-cluster --region us-west-2

# Verify the connection
echo "Verifying cluster connection..."
kubectl get nodes

echo "Kubeconfig updated successfully for us-west-2 region!" 