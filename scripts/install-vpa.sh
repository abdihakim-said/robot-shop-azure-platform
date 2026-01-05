#!/bin/bash
set -e

echo "🤖 Installing Vertical Pod Autoscaler (VPA)"
echo "==========================================="

echo "1️⃣ Installing VPA CRDs and components..."
kubectl apply -f https://github.com/kubernetes/autoscaler/releases/latest/download/vpa-crd.yaml
kubectl apply -f https://github.com/kubernetes/autoscaler/releases/latest/download/vpa-rbac.yaml
kubectl apply -f https://github.com/kubernetes/autoscaler/releases/latest/download/vpa-deployment.yaml

echo "2️⃣ Waiting for VPA components to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/vpa-admission-controller -n kube-system
kubectl wait --for=condition=available --timeout=300s deployment/vpa-recommender -n kube-system
kubectl wait --for=condition=available --timeout=300s deployment/vpa-updater -n kube-system

echo "3️⃣ Verifying VPA installation..."
kubectl get pods -n kube-system | grep vpa

echo ""
echo "✅ VPA installed successfully!"
echo "📊 VPA will now:"
echo "   - Monitor resource usage for 7 days"
echo "   - Automatically adjust CPU/memory requests"
echo "   - Restart pods with optimal resources"
echo ""
echo "🚀 Deploy your application with VPA enabled in values-dev.yaml"
