#!/bin/bash
set -e

echo "🚀 Robot Shop Enterprise Deployment (Netflix/Google Pattern)"
echo "============================================================"

# Environment validation
ENVIRONMENT="${1:-dev}"
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    echo "❌ Error: Invalid environment. Use: dev, staging, or prod"
    exit 1
fi

# Configuration
CHART_PATH="./helm-charts/robot-shop"
VALUES_FILE="./helm-charts/robot-shop/values-${ENVIRONMENT}.yaml"
NAMESPACE="robot-shop"
RELEASE_NAME="robot-shop"

echo "📦 Environment: $ENVIRONMENT"
echo "📁 Chart: $CHART_PATH"
echo "⚙️  Values: $VALUES_FILE"
echo ""

# Validate files exist
if [[ ! -f "$VALUES_FILE" ]]; then
    echo "❌ Error: Values file not found: $VALUES_FILE"
    exit 1
fi

# Build dependencies
echo "🔧 Building chart dependencies..."
cd "$CHART_PATH"
helm dependency build
cd - > /dev/null

# Deploy based on environment
case $ENVIRONMENT in
    dev)
        echo "🚀 Deploying to Development (Auto-deploy enabled)"
        helm upgrade --install $RELEASE_NAME $CHART_PATH \
            --values $VALUES_FILE \
            --namespace $NAMESPACE \
            --create-namespace \
            --timeout 10m \
            --wait
        ;;
    staging)
        echo "🚀 Deploying to Staging (Production-like)"
        helm upgrade --install $RELEASE_NAME $CHART_PATH \
            --values $VALUES_FILE \
            --namespace $NAMESPACE \
            --create-namespace \
            --timeout 15m \
            --wait \
            --atomic  # Rollback on failure
        ;;
    prod)
        echo "🚀 Deploying to Production (Manual approval required)"
        echo "⚠️  Production deployment requires manual confirmation"
        read -p "Deploy to PRODUCTION? (yes/no): " confirm
        if [[ $confirm != "yes" ]]; then
            echo "❌ Production deployment cancelled"
            exit 1
        fi
        
        helm upgrade --install $RELEASE_NAME $CHART_PATH \
            --values $VALUES_FILE \
            --namespace $NAMESPACE \
            --create-namespace \
            --timeout 20m \
            --wait \
            --atomic \
            --dry-run  # Safety check first
            
        echo "✅ Dry-run successful. Proceeding with actual deployment..."
        helm upgrade --install $RELEASE_NAME $CHART_PATH \
            --values $VALUES_FILE \
            --namespace $NAMESPACE \
            --timeout 20m \
            --wait \
            --atomic
        ;;
esac

# Verify deployment
echo ""
echo "✅ Deployment completed successfully!"
echo ""
echo "📊 Deployment Status:"
helm list -n $NAMESPACE
echo ""
echo "🔍 Pod Status:"
kubectl get pods -n $NAMESPACE -o wide
echo ""
echo "🌐 Services:"
kubectl get svc -n $NAMESPACE

# Environment-specific post-deployment info
case $ENVIRONMENT in
    dev)
        WEB_IP=$(kubectl get svc web -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "Pending...")
        echo ""
        echo "🔗 Development Access:"
        echo "   Web App: http://$WEB_IP:8080"
        ;;
    staging)
        echo ""
        echo "🔗 Staging Access:"
        echo "   Via Application Gateway (Private cluster)"
        ;;
    prod)
        echo ""
        echo "🔗 Production Access:"
        echo "   Via Application Gateway (Private cluster)"
        echo "   Monitor via Grafana dashboards"
        ;;
esac

echo ""
echo "🎉 Robot Shop $ENVIRONMENT deployment complete!"
