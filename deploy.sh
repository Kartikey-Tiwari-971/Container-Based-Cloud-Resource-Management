#!/bin/bash
set -e

# Add local bin to PATH if it exists
if [ -d "$(dirname "$0")/bin" ]; then
    export PATH="$(dirname "$0")/bin:$PATH"
fi

# Check for required tools
if ! command -v kind &> /dev/null; then
    echo "Error: kind is not installed."
    exit 1
fi

if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl is not installed."
    exit 1
fi

if ! command -v docker &> /dev/null; then
    echo "Error: docker is not installed."
    exit 1
fi

CLUSTER_NAME="cloud-resource-mgmt"
IMAGE_NAME="cloud-resource-app:latest"

echo "Checking if cluster $CLUSTER_NAME exists..."
if ! kind get clusters | grep -q "^$CLUSTER_NAME$"; then
    echo "Creating cluster $CLUSTER_NAME..."
    kind create cluster --name $CLUSTER_NAME
else
    echo "Cluster $CLUSTER_NAME already exists."
fi

echo "Building Docker image..."
docker build -t $IMAGE_NAME ./app

echo "Loading image into Kind..."
kind load docker-image $IMAGE_NAME --name $CLUSTER_NAME

echo "Applying Kubernetes Manifests..."
# Apply metrics server first
kubectl apply -f k8s/metrics-server.yaml

# Apply app manifests
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/hpa.yaml

echo "Waiting for deployment to be ready..."
# Give it a moment to start creating pods
sleep 5
kubectl wait --for=condition=available deployment/cloud-resource-app --timeout=120s

echo "Deployment complete!"
kubectl get all
