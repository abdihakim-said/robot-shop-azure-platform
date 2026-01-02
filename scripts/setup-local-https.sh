#!/bin/bash
set -e

echo "🔒 Setting up Self-Signed HTTPS for Local Development"
echo "===================================================="

echo "1️⃣ Creating self-signed ClusterIssuer..."
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: selfsigned-issuer
spec:
  selfSigned: {}
EOF

echo "2️⃣ Updating ingress resources to use self-signed certificates..."

# Update Grafana ingress
kubectl patch ingress monitoring-dev-grafana -n monitoring --type='merge' -p='{
  "metadata": {
    "annotations": {
      "cert-manager.io/cluster-issuer": "selfsigned-issuer",
      "nginx.ingress.kubernetes.io/ssl-redirect": "true"
    }
  }
}'

# Update Prometheus ingress
kubectl patch ingress monitoring-dev-prometheus -n monitoring --type='merge' -p='{
  "metadata": {
    "annotations": {
      "cert-manager.io/cluster-issuer": "selfsigned-issuer",
      "nginx.ingress.kubernetes.io/ssl-redirect": "true"
    }
  }
}'

# Update Robot Shop ingress
kubectl patch ingress web-ingress -n robot-shop --type='merge' -p='{
  "metadata": {
    "annotations": {
      "cert-manager.io/cluster-issuer": "selfsigned-issuer",
      "nginx.ingress.kubernetes.io/ssl-redirect": "true"
    }
  }
}'

# Update ArgoCD ingress
kubectl patch ingress argocd-server-ingress -n argocd --type='merge' -p='{
  "metadata": {
    "annotations": {
      "cert-manager.io/cluster-issuer": "selfsigned-issuer",
      "nginx.ingress.kubernetes.io/ssl-redirect": "true"
    }
  }
}'

echo "3️⃣ Waiting for self-signed certificates to be issued..."
sleep 10

echo "✅ Self-signed HTTPS setup complete!"
echo "==================================="
echo ""
echo "🔒 HTTPS URLs (with self-signed certificates):"
echo "📊 Grafana:     https://grafana.robot-shop-dev.com"
echo "📈 Prometheus:  https://prometheus.robot-shop-dev.com"
echo "🛒 Robot Shop:  https://robot-shop.robot-shop-dev.com"
echo "🚀 ArgoCD:      https://argocd.robot-shop-dev.com"
echo ""
echo "⚠️  Browser will show 'Not Secure' warning - click 'Advanced' → 'Proceed'"
echo "🎯 Perfect for local development and screenshots!"
echo ""
echo "📋 Check certificate status:"
echo "kubectl get certificates -A"
