#!/bin/bash
set -e

echo "🚀 Robot Shop Automated Deployment on Azure AKS"
echo "================================================"
echo ""

NAMESPACE="robot-shop"
RELEASE_NAME="robot-shop"
HELM_CHART="./helm"

# Environment selection
ENVIRONMENT="${1:-dev}"
case $ENVIRONMENT in
  dev)
    VALUES_FILE="./helm/values-dev.yaml"
    echo "📦 Environment: Development"
    echo "   Resources: Minimal (30m CPU)"
    ;;
  staging)
    VALUES_FILE="./helm/values-staging.yaml"
    echo "📦 Environment: Staging"
    echo "   Resources: Medium (40-75m CPU)"
    ;;
  prod)
    VALUES_FILE="./helm/values-prod.yaml"
    echo "📦 Environment: Production"
    echo "   Resources: Optimized (50-100m CPU)"
    ;;
  *)
    VALUES_FILE="./helm/values.yaml"
    echo "📦 Environment: Default"
    ;;
esac

echo "   Using: $VALUES_FILE"
echo ""

# Check if Helm release exists
if helm list -n $NAMESPACE 2>/dev/null | grep -q $RELEASE_NAME; then
  echo "📦 Existing deployment found"
  read -p "Do you want to upgrade? (y/n): " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🔄 Upgrading deployment..."
    helm upgrade $RELEASE_NAME $HELM_CHART \
      --namespace $NAMESPACE \
      --values $VALUES_FILE
  else
    echo "❌ Deployment cancelled"
    exit 0
  fi
else
  echo "🆕 New deployment"
  kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f - 2>/dev/null
  
  echo "🔄 Installing Robot Shop..."
  helm install $RELEASE_NAME $HELM_CHART \
    --namespace $NAMESPACE \
    --values $VALUES_FILE
fi

echo ""
echo "⏳ Waiting for pods to initialize (15 seconds)..."
sleep 15

echo ""
echo "📊 Deployment Status:"
echo "===================="
kubectl get pods -n $NAMESPACE

echo ""
echo "🎯 Cluster Nodes:"
kubectl get nodes

echo ""
echo "📈 Resource Usage:"
kubectl top nodes 2>/dev/null || echo "Metrics not available yet"

echo ""
echo "🌐 Web Service:"
kubectl get svc web -n $NAMESPACE 2>/dev/null || echo "Web service not ready yet"

echo ""
echo "✅ Deployment Complete!"
echo ""
echo "📝 Access the application:"
WEB_IP=$(kubectl get svc web -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
if [ -n "$WEB_IP" ] && [ "$WEB_IP" != "null" ]; then
  echo "   🔗 http://$WEB_IP:8080"
else
  echo "   ⏳ LoadBalancer IP pending... Check with:"
  echo "      kubectl get svc web -n $NAMESPACE"
fi

echo ""
echo "🔍 Useful commands:"
echo "   Monitor pods:     kubectl get pods -n $NAMESPACE -w"
echo "   Check logs:       kubectl logs -n $NAMESPACE <pod-name>"
echo "   Port forward:     kubectl port-forward -n $NAMESPACE svc/web 8080:8080"
echo "   Uninstall:        helm uninstall $RELEASE_NAME -n $NAMESPACE"
echo ""
echo "💡 Deploy to different environment:"
echo "   ./deploy-robot-shop.sh dev      # Development (minimal)"
echo "   ./deploy-robot-shop.sh staging  # Staging (medium)"
echo "   ./deploy-robot-shop.sh prod     # Production (optimized)"
