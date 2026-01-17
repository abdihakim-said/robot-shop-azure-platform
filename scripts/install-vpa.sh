#!/bin/bash
set -e

echo "🤖 Installing Vertical Pod Autoscaler (VPA) via Helm"
echo "===================================================="

echo "1️⃣ Adding Fairwinds Helm repository..."
helm repo add fairwinds-stable https://charts.fairwinds.com/stable
helm repo update

echo "2️⃣ Installing VPA..."
helm upgrade --install vpa fairwinds-stable/vpa \
  --namespace kube-system \
  --set recommender.enabled=true \
  --set updater.enabled=true \
  --set admissionController.enabled=true

echo "3️⃣ Waiting for VPA components to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/vpa-admission-controller -n kube-system
kubectl wait --for=condition=available --timeout=300s deployment/vpa-recommender -n kube-system  
kubectl wait --for=condition=available --timeout=300s deployment/vpa-updater -n kube-system

echo "4️⃣ Verifying VPA installation..."
kubectl get pods -n kube-system | grep vpa

echo ""
echo "✅ VPA installed successfully!"
echo "📊 VPA will now:"
echo "   - Monitor resource usage patterns"
echo "   - Automatically adjust CPU/memory requests"
echo "   - Restart pods with optimal resources"
echo ""
echo "🚀 Deploy your application with VPA enabled in values-dev.yaml"
