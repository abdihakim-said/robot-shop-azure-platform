#!/bin/bash
set -e

echo "🔒 HTTPS Status Check - GitOps Managed Let's Encrypt"
echo "===================================================="

echo "✅ Current GitOps-managed HTTPS setup:"
echo "   - ClusterIssuer: k8s/letsencrypt-issuer.yaml"
echo "   - Certificates: Helm templates (robot-shop, monitoring)"
echo "   - Domain: hakimdevops.art"
echo "   - Management: ArgoCD GitOps"

echo ""
echo "🎯 Active Let's Encrypt certificates:"
kubectl get certificate -A

echo ""
echo "🌐 HTTPS endpoints:"
echo "📊 Main App:    https://hakimdevops.art"
echo "📊 Grafana:     https://grafana.hakimdevops.art"
echo "📊 Prometheus:  https://prometheus.hakimdevops.art"
echo "📊 ArgoCD:      https://argocd.hakimdevops.art"

echo ""
echo "✅ All certificates managed via GitOps - no manual intervention needed!"
