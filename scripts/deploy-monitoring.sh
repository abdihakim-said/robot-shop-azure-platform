#!/bin/bash

# Deploy Monitoring Stack by Environment
# Usage: ./scripts/deploy-monitoring.sh <environment>

set -e

ENVIRONMENT=${1:-dev}
NAMESPACE="monitoring"

if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    echo "Error: Environment must be dev, staging, or prod"
    echo "Usage: $0 <environment>"
    exit 1
fi

echo "🚀 Deploying monitoring stack for $ENVIRONMENT environment..."

# Create namespace if it doesn't exist
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Add prometheus-community helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Deploy with environment-specific values
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
    --namespace $NAMESPACE \
    --values helm/values-monitoring-${ENVIRONMENT}.yaml \
    --wait \
    --timeout 10m

echo "✅ Monitoring stack deployed successfully for $ENVIRONMENT"
echo ""
echo "Access Grafana:"
echo "kubectl port-forward -n $NAMESPACE svc/monitoring-grafana 3000:80"
echo ""
echo "Access Prometheus:"
echo "kubectl port-forward -n $NAMESPACE svc/monitoring-kube-prometheus-prometheus 9090:9090"
