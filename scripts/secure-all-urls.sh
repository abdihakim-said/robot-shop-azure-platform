#!/bin/bash
set -e

echo "🔒 Setting up automated HTTPS for ALL applications"
echo "================================================="

echo "1️⃣ Installing cert-manager..."
helm repo add jetstack https://charts.jetstack.io
helm repo update

helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.13.0 \
  --set installCRDs=true

echo "2️⃣ Waiting for cert-manager to be ready..."
kubectl wait --for=condition=ready pod -l app=cert-manager -n cert-manager --timeout=60s
kubectl wait --for=condition=ready pod -l app=webhook -n cert-manager --timeout=60s
kubectl wait --for=condition=ready pod -l app=cainjector -n cert-manager --timeout=60s

echo "3️⃣ Creating Let's Encrypt ClusterIssuer..."
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: abdihakimsaid1@gmail.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF

echo "4️⃣ Securing Grafana (Monitoring Dashboard)..."
kubectl patch ingress monitoring-dev-grafana -n monitoring --type='merge' -p='{
  "metadata": {
    "annotations": {
      "cert-manager.io/cluster-issuer": "letsencrypt-prod",
      "nginx.ingress.kubernetes.io/ssl-redirect": "true"
    }
  },
  "spec": {
    "tls": [{
      "hosts": ["grafana.robot-shop-dev.com"],
      "secretName": "grafana-tls"
    }]
  }
}'

echo "5️⃣ Securing Prometheus (Metrics Dashboard)..."
kubectl patch ingress monitoring-dev-prometheus -n monitoring --type='merge' -p='{
  "metadata": {
    "annotations": {
      "cert-manager.io/cluster-issuer": "letsencrypt-prod",
      "nginx.ingress.kubernetes.io/ssl-redirect": "true"
    }
  },
  "spec": {
    "tls": [{
      "hosts": ["prometheus.robot-shop-dev.com"],
      "secretName": "prometheus-tls"
    }]
  }
}'

echo "6️⃣ Securing Robot Shop Application (Main App)..."
kubectl patch ingress web-ingress -n robot-shop --type='merge' -p='{
  "metadata": {
    "annotations": {
      "cert-manager.io/cluster-issuer": "letsencrypt-prod",
      "nginx.ingress.kubernetes.io/ssl-redirect": "true"
    }
  },
  "spec": {
    "tls": [{
      "hosts": ["robot-shop.robot-shop-dev.com"],
      "secretName": "robot-shop-tls"
    }]
  }
}'

echo "7️⃣ Securing ArgoCD (GitOps Dashboard)..."
kubectl patch ingress argocd-server-ingress -n argocd --type='merge' -p='{
  "metadata": {
    "annotations": {
      "cert-manager.io/cluster-issuer": "letsencrypt-prod",
      "nginx.ingress.kubernetes.io/ssl-redirect": "true"
    }
  },
  "spec": {
    "tls": [{
      "hosts": ["argocd.robot-shop-dev.com"],
      "secretName": "argocd-tls"
    }]
  }
}'

echo "8️⃣ Waiting for certificates to be issued..."
echo "This may take 2-3 minutes for Let's Encrypt validation..."

sleep 60

echo "✅ HTTPS automation complete!"
echo "============================"
echo ""
echo "🔒 ALL SECURED URLS:"
echo "📊 Grafana:     https://grafana.robot-shop-dev.com"
echo "📈 Prometheus:  https://prometheus.robot-shop-dev.com"
echo "🛒 Robot Shop:  https://robot-shop.robot-shop-dev.com"
echo "🚀 ArgoCD:      https://argocd.robot-shop-dev.com"
echo ""
echo "📋 Check certificate status:"
echo "kubectl get certificates -A"
echo ""
echo "🎯 Perfect for SS&C interview demos!"
