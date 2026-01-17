#!/bin/bash

# Setup NGINX Ingress Controller for AKS
set -e

echo "🚀 Setting up NGINX Ingress Controller..."

# Add ingress-nginx helm repo
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Install NGINX Ingress Controller
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
    --namespace ingress-nginx \
    --create-namespace \
    --set controller.service.type=LoadBalancer \
    --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz \
    --wait

echo "✅ NGINX Ingress Controller installed"

# Get external IP
echo "⏳ Waiting for external IP..."
kubectl get svc -n ingress-nginx ingress-nginx-controller --watch

echo ""
echo "📝 Next steps:"
echo "1. Point DNS records to the external IP:"
echo "   grafana.robot-shop.com -> <EXTERNAL-IP>"
echo "   prometheus.robot-shop.com -> <EXTERNAL-IP>"
echo ""
echo "2. Create TLS certificates:"
echo "   kubectl create secret tls grafana-tls --cert=grafana.crt --key=grafana.key -n monitoring"
echo "   kubectl create secret tls prometheus-tls --cert=prometheus.crt --key=prometheus.key -n monitoring"
