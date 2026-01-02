#!/bin/bash
set -e

echo "🚀 Deploying Staging Environment for Monitoring Showcase"
echo "======================================================="

# Set Stripe secrets for staging (use environment variables or Azure Key Vault)
export TF_VAR_stripe_secret_key="${STRIPE_SECRET_KEY:-sk_test_PLACEHOLDER}"
export TF_VAR_stripe_publishable_key="${STRIPE_PUBLISHABLE_KEY:-pk_test_PLACEHOLDER}"

echo "1️⃣ Deploying staging infrastructure..."
cd terraform/environments/staging
terraform init
terraform apply -auto-approve

echo "2️⃣ Getting AKS credentials..."
CLUSTER_NAME=$(terraform output -raw aks_cluster_name)
RESOURCE_GROUP=$(terraform output -raw resource_group_name)
az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$CLUSTER_NAME" --overwrite-existing

echo "3️⃣ Installing NGINX Ingress Controller..."
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=LoadBalancer

echo "4️⃣ Waiting for Load Balancer IP..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

EXTERNAL_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "✅ Load Balancer IP: $EXTERNAL_IP"

echo "5️⃣ Deploying applications..."
kubectl apply -f ../../argocd/robot-shop-staging.yaml
kubectl apply -f ../../argocd-apps/monitoring-staging.yaml

echo "✅ Staging deployment complete!"
echo ""
echo "🌐 Access URLs (add to /etc/hosts):"
echo "$EXTERNAL_IP grafana.robot-shop-staging.com"
echo "$EXTERNAL_IP prometheus.robot-shop-staging.com"
echo "$EXTERNAL_IP robot-shop.robot-shop-staging.com"
echo ""
echo "📊 Grafana: http://grafana.robot-shop-staging.com"
echo "📈 Prometheus: http://prometheus.robot-shop-staging.com"
echo "🛒 Robot Shop: http://robot-shop.robot-shop-staging.com"
