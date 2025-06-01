#!/bin/bash

set -e

echo "📦 Installing kubectl..."

# Create keyrings directory if it doesn't exist
sudo mkdir -p /etc/apt/keyrings

# Download and save Kubernetes signing key
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Add Kubernetes APT repository
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Update package list and install kubectl
sudo apt-get update
sudo apt-get install -y kubectl

# Verify kubectl installation
echo "✅ kubectl installed successfully:"
kubectl version --client
